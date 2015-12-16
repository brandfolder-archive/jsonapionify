module JSONAPIonify::Api
  class Response
    attr_reader :action, :accept, :response_block, :status

    def initialize(action, accept: nil, status: nil, &block)
      @action         = action
      @response_block = block || proc {}
      @accept         = accept || 'application/vnd.api+json'
      @status         = status || 200
    end

    def ==(other)
      self.class == other.class &&
        %i{@accept}.all? do |ivar|
          instance_variable_get(ivar) == other.instance_variable_get(ivar)
        end
    end

    def accept?(request)
      request.accept.any? do |accept|
        @accept == accept || accept == '*/*' || self.accept == '*/*'
      end
    end

    def documentation_object
      OpenStruct.new(
        accept:       accept,
        content_type: accept,
        status:       status
      )
    end

    def call(instance, context)
      response = self
      instance.instance_eval do
        body = instance_exec(context, &response.response_block)
        Rack::Response.new.tap do |rack_response|
          rack_response.status = response.status
          response_headers.each { |k, v| rack_response.headers[k] = v }
          rack_response.headers['content-type'] = response.accept unless response.accept == '*/*'
          rack_response.write(body) unless body.nil?
        end.finish
      end
    end

  end
end
