require 'mime-types'

module JSONAPIonify::Api
  class Response
    attr_reader :action, :accept, :mime_types, :response_block, :status,
                :matcher, :content_type

    def initialize(action, accept: 'application/vnd.api+json', content_type: nil, status: nil, match: nil, &block)
      @action         = action
      @response_block = block || proc {}
      @accept         = accept unless match
      @content_type   = content_type || (@accept == '*/*' ? nil : @accept)
      @matcher        = match || proc {}
      @mime_types     = MIME::Types[@accept]
      @status         = status || 200
    end

    def ==(other)
      self.class == other.class &&
        %i{@accept}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def documentation_object
      OpenStruct.new(
        accept:       accept,
        content_type: accept,
        status:       status
      )
    end

    def call(instance, context, status: nil)
      status   ||= self.status
      response = self
      instance.instance_eval do
        body = instance_exec(context, &response.response_block)
        Rack::Response.new.tap do |rack_response|
          rack_response.status = status
          response_headers.each do |k, v|
            rack_response.headers[k.split('-').map(&:capitalize).join('-')] = v
          end
          rack_response.headers['Content-Type'] =
            case response.content_type
            when nil
              raise(Errors::MissingContentType, 'missing content type')
            when Proc
              response.content_type.call(context)
            else
              response.content_type
            end
          rack_response.write(body) unless body.nil?
        end.finish
      end
    end

    def accept_with_header?(context)
      return false unless MIME::Types.of(context.request.path).blank?
      context.request.accept.any? do |accept|
        self.accept == accept || self.accept == '*/*' || accept == '*/*'
      end
    end

    def accept_with_path?(context)
      [mime_types, MIME::Types.of(context.request.path)].reduce(:&).present?
    end

    def accept_with_matcher?(context)
      !!matcher.call(context)
    end

  end
end
