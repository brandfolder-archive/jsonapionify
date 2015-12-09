module JSONAPIonify::Api
  module Resource::ErrorHandling
    extend ActiveSupport::Concern

    module ClassMethods
      def self.extended(klass)
        klass.include ActiveSupport::Rescuable
      end

      def error(name, &block)
        self.error_definitions = self.error_definitions.merge name.to_sym => block
      end

      def rescue_from(*klasses, error:)
        super *klasses do |exception|
          error(error, exception.message)
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

    def error(name, **options)
      error = self.class.error_definitions[name]
      raise ArgumentError, "Error does not exist: #{name}" unless error
      errors.evaluate(**options, &self.class.error_definitions[name])
    end

    def error_now(*args)
      error(*args)
      raise error_exception
    end

    def error_meta
      errors.meta
    end

    private

    def error_exception
      @error_exception ||= Class.new(StandardError)
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