module JSONAPIonify::Api
  module Resource::Defaults::Actions
    extend ActiveSupport::Concern

    included do
      context(:action_name){}
      define_action(:options, 'OPTIONS', '*', cacheable: true, callbacks: false) do
        cache 'options-request'
      end.response(status: 200) do |context|
        response_headers['Allow'] = context.http_allow
        requests                  = context.http_allow.each_with_object({}) do |method, h|
          h[method] =
            case method
            when 'GET'
              {
                attributes:    attributes.select(&:read).map(&:options_json),
                relationships: self.class.relationships.map(&:options_json)
              }
            when 'POST', 'PUT', 'PATCH'
              { attributes: attributes.select(&:write).map(&:options_json) }
            else
              {}
            end
        end
        JSONAPIonify.new_object(
          meta: {
            type:     self.class.type,
            requests: requests
          }
        ).to_json
      end

      before(:create) { |context| context.instance = context.new_instance }
      read
    end
  end
end
