module JSONAPIonify::Api
  module Resource::ErrorHandling
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Rescuable
      context(:error_exception) { Class.new(StandardError) }
    end

    module ClassMethods

      def error(name, &block)
        self.error_definitions = self.error_definitions.merge name.to_sym => block
      end

      def rescue_from(*klasses, error:)
        super(*klasses) do
          error_now error
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
      error = self.class.error_definitions[name]
      raise ArgumentError, "Error does not exist: #{name}" unless error
      errors.evaluate(*args, error_block: self.class.error_definitions[name], runtime_block: block)
    end

    def error_now(*args, &block)
      error(*args, &block)
      raise error_exception
    end

    def set_errors(collection)
      errors.set collection
    end

    def error_meta
      errors.meta
    end

    private

    def rescued_response(exception)
      rescue_with_handler(exception) || begin
        error :internal_server_error do
          if ENV['RACK_ENV'] == 'development'
            detail exception.message
            meta[:error_class] = exception.class.name
            meta[:backtrace]   = exception.backtrace
          end
        end
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
        headers.each { |k, v| response.headers[k] = v }
        response.headers['content-type'] = 'application/vnd.api+json'
        response.write(errors.top_level.to_json)
      end.finish
    end

  end
end
