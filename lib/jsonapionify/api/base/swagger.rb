require 'active_support/core_ext/class/attribute'

module JSONAPIonify::Api
  module Base::Swagger

    def process_swagger(request)
      headers                    = resource_class.new(request: request).exec { |c| c.response_headers }
      obj = SwaggerBuilder.new(self, request)
      Rack::Response.new.tap do |response|
        response.status = 200
        headers.each { |k, v| response[k] = v }
        response['content-type'] = 'application/json'
        response.write obj.to_json
      end.finish
    end

  private

  end
end
