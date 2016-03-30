module JSONAPIonify::Api
  module Resource::Defaults::Actions
    extend ActiveSupport::Concern

    included do
      context :path_actions, readonly: true do |context|
        self.class.path_actions(context.request)
      end
      context :http_allow, readonly: true do |context|
        context.path_actions.map(&:request_method)
      end
      context(:action_name){}
      define_action(:options, 'OPTIONS', '*', cacheable: true, callbacks: false) do
        cache 'options-request'
      end.response(status: 200) do |context|
        response_headers['Allow'] = context.http_allow.join(', ')
        requests                  = context.path_actions.each_with_object({}) do |action, h|
          action_options_json = attributes.select do |attr|
            attr.supports_action? action.name
          end.map do |attr|
            attr.options_json_for_action(action.name)
          end

          action_options = h[action.request_method] = {}

          if [ 'GET', 'POST', 'PUT', 'PATCH' ].include? action.request_method
            action_options[:attributes] = action_options_json
          end

          if [ 'GET' ].include? action.request_method
            action_options[:relationships] =
              self.class.relationships.map(&:options_json)
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
