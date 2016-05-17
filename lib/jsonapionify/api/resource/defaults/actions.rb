module JSONAPIonify::Api
  module Resource::Defaults::Actions
    extend ActiveSupport::Concern

    included do
      context :path_actions, readonly: true, persisted: true do |context|
        self.class.path_actions(context.request).freeze
      end

      context :http_allow, readonly: true, persisted: true do |context|
        context.path_actions.map(&:request_method).freeze
      end

      context(:action_name, persisted: true) {}
      define_action(:options, 'OPTIONS', '*', cacheable: true, callbacks: false) do
        cache 'options-request'
      end.response(status: 200) do |context|
        response_headers['Allow'] = context.http_allow.join(', ')
        requests                  = context.path_actions.each_with_object({}) do |action, h|
          request_attributes_json = attributes.select do |attr|
            attr.supports_write_for_action? action.name, context
          end.map do |attr|
            attr.options_json_for_action(action.name, context)
          end

          response_attributes_json = attributes.select do |attr|
            attr.supports_read_for_action? action.name, context
          end.map do |attr|
            attr.options_json_for_action(action.name, context)
          end

          h['path']      = context.request.path
          h['url']       = context.request.url
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

      before(:create) { |context| context.instance = context.new_instance }
      read
    end
  end
end
