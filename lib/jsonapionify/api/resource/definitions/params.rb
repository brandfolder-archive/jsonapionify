module JSONAPIonify::Api
  module Resource::Definitions::Params

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :param_definitions

        context(:params, readonly: true, persisted: true) do |request:, action_name:|
          defined_params = self.class.param_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end
          param_defaults = defined_params.values.select(&:has_default?).map(&:default)
          [*param_defaults, request.params].reduce(:deep_merge)
        end

        # Validate params before request
        before do |params:, action_name:, request:, nested_request: false|
          defined_params = self.class.param_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end

          required_params = defined_params.select do |_, v|
            v.required
          end

          # Check for validity
          params.each do |k, v|
            keypath  = ParamOptions.hash_to_keypaths(k => v)[0]
            reserved = ParamOptions.reserved?(k)
            allowed  = defined_params.keys.include? keypath
            valid    = ParamOptions.valid?(k) || v.is_a?(Hash)
            unless reserved || (allowed && valid) || nested_request
              error :parameter_invalid, ParamOptions.keypath_to_string(*keypath)
            end
          end unless request.options?

          # Check for requirement
          missing_params = ParamOptions.missing_parameters(
            request.params, required_params.values.map(&:keypath)
          )
          error :parameters_missing, missing_params if !nested_request && missing_params.present?
        end

      end
    end

    def param(*keypath, **options)
      param_definitions[keypath] = ParamOptions.new(*keypath, **options)
    end

    def sticky_params(params)
      sticky_param_definitions = param_definitions.values.select(&:sticky)
      ParamOptions.hash_to_keypaths(params).map do |keypath|
        definition = sticky_param_definitions.find do |d|
          d.keypath == keypath
        end
        next {} unless definition
        value = definition.extract_value(params)
        if definition.default_value?(value)
          {}
        else
          definition.with_value(value)
        end
      end.reduce(:deep_merge)
    end

  end
end
