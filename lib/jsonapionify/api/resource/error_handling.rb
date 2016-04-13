require 'unstrict_proc'

module JSONAPIonify::Api
  module Resource::ErrorHandling
    extend ActiveSupport::Concern
    using UnstrictProc

    included do
      include ActiveSupport::Rescuable
      context(:errors, readonly: true) do
        ErrorsObject.new
      end
      register_exception Exception, error: :internal_server_error do
        if verbose_errors
          detail exception.message
          meta[:error_class] = exception.class.name
        end
      end
    end

    module ClassMethods

      def error(name, &block)
        self.error_definitions = self.error_definitions.merge name.to_sym => block
      end

      def register_exception(*klasses, error:, &block)
        rescue_from(*klasses) do |exception|
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

      def sorted_rescue_handlers
        handlers           = self.rescue_handlers.dup
        # logic to find invalid order
        out_of_order_class = lambda do |klasses|
          klass_index  = nil
          parent_index = nil
          klass        = klasses.find do |klass|
            klass_index  = klasses.find_index { |k| k == klass }
            parent_index = klasses[0..klass_index].find_index { |k| k < klass }
          end
          klass ? [klass_index, parent_index] : nil
        end

        # Map handler classes
        klasses            = handlers.map do |klass_name, _|
          klass = self.class.const_get(klass_name) rescue nil
          klass ||= klass_name.constantize rescue nil
          klass
        end

        # Loop until things are ordered
        while (result = out_of_order_class[klasses])
          klass_index, parent_index = result
          handler                   = klasses.delete_at klass_index
          handlers                  = [*handlers[0..parent_index-1], handler, *handlers[parent_index..-1]]
        end
        handlers.reverse
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

    def handler_for_rescue(exception)
      _, rescuer = self.class.sorted_rescue_handlers.find do |klass_name, _|
        klass = self.class.const_get(klass_name) rescue nil
        klass ||= klass_name.constantize rescue nil
        exception.is_a?(klass) if klass
      end

      case rescuer
      when Symbol
        method(rescuer)
      when Proc
        rescuer
      end
    end

    # Tries to rescue the exception by looking up and calling a registered handler.
    def rescue_with_handler(exception, context, respond_proc)
      if (handler = handler_for_rescue(exception))
        status, headers, body =
          instance_exec exception, context, respond_proc, &handler.unstrict
        if status.is_a?(Fixnum) && headers.is_a?(Hash) && body.respond_to?(:each)
          [status, headers, body]
        else
          error_response
        end
      end
    end

    def rescued_response(exception, context, respond_proc)
      rescue_with_handler(exception, context, respond_proc) ||
        fail(Exception)
    rescue Exception
      return error_response
    end

    def error_response
      Rack::Response.new.tap do |response|
        error :internal_server_error unless errors.present?
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
