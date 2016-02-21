module JSONAPIonify::Api
  module Resource::ErrorHandling
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Rescuable
      context(:errors, readonly: true) do
        ErrorsObject.new
      end
    end

    module ClassMethods

      def error(name, &block)
        self.error_definitions = self.error_definitions.merge name.to_sym => block
      end

      def rescue_from(*klasses, error:, &block)
        super(*klasses) do |exception|
          errors.evaluate(
            error_block:   lookup_error(error),
            runtime_block: block || proc {},
            backtrace:     exception.backtrace
          )
        end
      end

      def error_definitions=(hash)
        @error_definitions = hash
      end

      def error_definitions
        @error_definitions ||= {}
        if superclass.respond_to?(:error_definitions)
          superclass.error_definitions.merge(@error_definitions)
        else
          @error_definitions
        end
      end
    end

    def error(name, *args, &block)
      errors.evaluate(
        *args,
        error_block:   lookup_error(name),
        runtime_block: block
      )
    end

    def error_now(name, *args, &block)
      error(name, *args, &block)
      raise Errors::RequestError
    end

    def set_errors(collection)
      errors.set collection
    end

    def error_meta
      errors.meta
    end

    private

    def lookup_error(name)
      self.class.error_definitions[name].tap do |error|
        raise ArgumentError, "Error does not exist: #{name}" unless error
      end
    end

    def rescued_response(exception)
      rescue_with_handler(exception) || begin
        verbose_errors = self.class.api.verbose_errors
        run_callbacks(:exception, exception)
        errors.evaluate(
          error_block:   lookup_error(:internal_server_error),
          runtime_block: proc {
            if verbose_errors
              detail exception.message
              meta[:error_class] = exception.class.name
            end
          },
          backtrace:     exception.backtrace
        )
      end
    ensure
      return error_response
    end

    def error_response
      Rack::Response.new.tap do |response|
        error_collection = errors.collection
        status_codes     = error_collection.map { |error| error[:status] }.compact.uniq.sort
        response.status  =
          if status_codes.length == 1
            status_codes[0].to_i
          elsif status_codes.blank?
            500
          else
            (status_codes.last[0] + "00").to_i
          end
        response_headers.each { |k, v| response.headers[k] = v }
        response.headers['content-type'] = 'application/vnd.api+json'
        response.write(errors.top_level.to_json)
      end.finish
    end

  end
end
