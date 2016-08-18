module JSONAPIonify::Api
  module Resource::Defaults::Actions
    extend ActiveSupport::Concern

    included do
      context :path_actions, readonly: true, persisted: true do |request:|
        self.class.path_actions(request)
      end

      context :http_allow, readonly: true, persisted: true do |path_actions:|
        path_actions.map(&:request_method)
      end

      context(:action_name, persisted: true) do
        action&.name
      end

      define_action(:options, 'OPTIONS', '{path*}', cacheable: true, callbacks: false) do
        cache 'options-request'
      end.response(status: 200) do |context, request:, http_allow:, path_actions:|
        response_headers['Allow'] = http_allow.join(', ')
        requests                  = path_actions.each_with_object({}) do |action, h|
          request_attributes_json = attributes.select do |attr|
            attr.supports_write_for_action? action.name, context
          end.map do |attr|
            attr.options_json_for_action(action.name, context)
          end

          response_attributes_json = attributes.select do |attr|
            attr.supports_read_for_action? action.name, context
          end.map do |attr|
            attr.options_json_for_action action.name, context
          end

          h['path']      = request.path
          h['url']       = request.url
          action_options = h[action.request_method] = {}

          if ['GET', 'POST', 'PUT', 'PATCH'].include? action.request_method
            action_options[:response_attributes] = response_attributes_json
            action_options[:relationships]       = self.class.relationships.map(&:options_json)
          end

          if ['POST', 'PUT', 'PATCH'].include? action.request_method
            action_options[:request_attributes] = request_attributes_json
          end
        end
        JSONAPIonify.new_object(
          meta: {
            type:     self.class.type,
            requests: requests
          }
        ).to_json
      end

      before(:create) do |context|
        context.instance = context.new_instance
      end
      read
    end
  end
end
