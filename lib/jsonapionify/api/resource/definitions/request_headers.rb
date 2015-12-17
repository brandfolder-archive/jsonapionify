module JSONAPIonify::Api
  module Resource::Definitions::RequestHeaders

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :request_header_definitions

        # Standard HTTP Headers
        # https://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Request_fields
        request_header 'accept'
        request_header 'accept-charset'
        request_header 'accept-encoding'
        request_header 'accept-language'
        request_header 'accept-datetime'
        request_header 'authorization'
        request_header 'cache-control'
        request_header 'connection'
        request_header 'cookie'
        request_header 'content-length'
        request_header 'content-md5'
        request_header 'content-type'
        request_header 'date'
        request_header 'expect'
        request_header 'from'
        request_header 'host'
        request_header 'if-match'
        request_header 'if-modified-since'
        request_header 'if-none-match'
        request_header 'if-range'
        request_header 'if-unmodified-since'
        request_header 'max-forwards'
        request_header 'origin'
        request_header 'pragma'
        request_header 'proxy-authorization'
        request_header 'range'
        request_header 'referer'
        request_header 'te'
        request_header 'user-agent'
        request_header 'upgrade'
        request_header 'via'
        request_header 'warning'

        # Non-Standard, but widely used HTTP headers
        request_header 'x-requested-with'
        request_header 'dnt'
        request_header 'x-forwarded-for'
        request_header 'x-forwarded-host'
        request_header 'x-forwarded-proto'
        request_header 'front-end-https'
        request_header 'x-att-device-id'
        request_header 'x-wap-profile'
        request_header 'proxy-connection'
        request_header 'x-uidh'
        request_header 'upgrade-insecure-requests'

        # Don't allow method overrides
        # request_header 'x-http-method-override'

        # Don't allow CSRF tokens, as they should not be used
        # in the api by default
        # request_header 'x-csrf-token'

        before do |context|
          context.request_headers # pull request_headers so they verify
        end

        context(:request_headers) do |context|
          should_error     = false

          # Check for validity
          headers          = self.class.request_header_definitions.select do |_, v|
            v.actions.blank? || v.actions.include?(action_name)
          end
          required_headers = headers.select do |_, v|
            v.required
          end

          if (invalid_keys = context.request.headers.keys.map(&:downcase) - headers.keys.map(&:downcase)).present?
            should_error = true
            invalid_keys.each do |key|
              error :header_not_permitted, key
            end
          end

          if (missing_keys = required_headers.keys.map(&:downcase) - context.request.headers.keys.map(&:downcase)).present?
            should_error = true
            error :headers_missing, missing_keys
          end

          raise error_exception if should_error

          context.request.headers
        end
      end
    end

    def request_header(name, **options)
      request_header_definitions[name] = HeaderOptions.new(name, **options)
    end

  end
end
