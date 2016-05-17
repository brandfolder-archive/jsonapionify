module JSONAPIonify::Api
  module Resource::Definitions::Params

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :param_definitions

        context(:params, readonly: true, persisted: true) do |context|
          should_error = false

          params = self.class.param_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end

          context.request.params.replace(
            [*params.values.select(&:has_default?).map(&:default), context.request.params].reduce(:deep_merge)
          )

          required_params = params.select do |_, v|
            v.required
          end

          # Check for validity
          context.request.params.each do |k, v|
            keypath  = ParamOptions.hash_to_keypaths(k => v)[0]
            reserved = ParamOptions.reserved?(k)
            allowed  = params.keys.include? keypath
            valid    = ParamOptions.valid?(k) || v.is_a?(Hash)
            unless reserved || (allowed && valid) || !context.root_request?
              should_error = true
              error :parameter_invalid, ParamOptions.keypath_to_string(*keypath)
            end
          end unless context.request.options?

          # Check for requirement
          missing_params =
            ParamOptions.missing_parameters(
              context.request.params,
              required_params.values.map(&:keypath)
            )
          if context.root_request? && missing_params.present?
            error :parameters_missing, missing_params
          end

          if should_error
            raise Errors::RequestError
          end

          # Return the params
          context.request.params
        end

      end
    end

    def param(*keypath, **options)
      param_definitions[keypath] = ParamOptions.new(*keypath, **options)
    end

    def sticky_params(params)
      sticky_param_definitions = param_definitions.values.select(&:sticky)
      ParamOptions.hash_to_keypaths(params).map do |keypath|
        definition = sticky_param_definitions.find do |definition|
          definition.keypath == keypath
        end
        next {} unless definition
        value      = definition.extract_value(params)
        if definition.default_value?(value)
          {}
        else
          definition.with_value(value)
        end
      end.reduce(:deep_merge)
    end

  end
end
