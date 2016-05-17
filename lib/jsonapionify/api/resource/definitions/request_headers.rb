module JSONAPIonify::Api
  module Resource::Definitions::RequestHeaders

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :request_header_definitions

        context(:request_headers, persisted: true, readonly: true) do |context|
          should_error     = false

          # Check for validity
          headers          = self.class.request_header_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end
          required_headers = headers.select do |_, v|
            v.required
          end

          missing_keys =
            required_headers.keys.map(&:downcase) -
              context.request.headers.keys.map(&:downcase)
          if context.root_request? && missing_keys.present?
            should_error = true
            error :headers_missing, missing_keys
          end

          raise Errors::RequestError if should_error

          context.request.headers.freeze
        end
      end
    end

    def request_header(name, **options)
      request_header_definitions[name] = HeaderOptions.new(name, **options)
    end

  end
end
