module JSONAPIonify::Api
  module Resource::Definitions::RequestHeaders

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :request_header_definitions

        # Define context
        context(:request_headers, persisted: true, readonly: true) do |request:|
          request.headers
        end

        # Validate headers before request
        before do |request_headers:, action_name:, nested_request: false|
          # Gather Definitions
          defined_headers = self.class.request_header_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end

          # Gather required Headers
          required_headers = defined_headers.select do |_, v|
            v.required
          end

          # Gather Missing Keys
          missing_keys = required_headers.keys.map(&:downcase) - request_headers.keys.map(&:downcase)
          error :headers_missing, missing_keys if !nested_request && missing_keys.present?
        end
      end
    end

    def request_header(name, **options)
      request_header_definitions[name] = HeaderOptions.new(name, **options)
    end

  end
end
