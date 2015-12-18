module JSONAPIonify::Api
  module Resource::Definitions::Params

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :param_definitions

        context(:params, readonly: true) do |context|
          should_error    = false

          # Check for validity
          params          = self.class.param_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end
          required_params = params.select do |_, v|
            v.required
          end
          if (invalid_params = ParamOptions.invalid_parameters(context.request.params, params.values.map(&:keypath))).present?
            should_error = true
            invalid_params.each do |string|
              error :parameter_not_permitted, string
            end
          end

          # Check for requirement
          if (missing_params = ParamOptions.missing_parameters(context.request.params, required_params.values.map(&:keypath))).present?
            error :parameters_missing, missing_params
          end

          raise Errors::RequestError if should_error

          # Return the params
          context.request.params
        end

      end
    end

    def param(*keypath, **options)
      param_definitions[keypath] = ParamOptions.new(*keypath, **options)
    end

    def sticky_params(params)
      sticky_param_paths = param_definitions.values.select(&:sticky).map(&:keypath)
      params.select do |k, v|
        sticky_param_paths.include? ParamOptions.hash_to_keypaths(k => v)[0]
      end
    end

  end
end
