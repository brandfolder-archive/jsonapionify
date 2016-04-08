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
          request_attributes_json = attributes.select do |attr|
            attr.supports_write_for_action? action.name, context
          end.map do |attr|
            attr.options_json_for_action(action.name, context)
          end
          puts 'got request attrs'

          response_attributes_json = attributes.select do |attr|
            attr.supports_read_for_action? action.name, context
          end.map do |attr|
            attr.options_json_for_action(action.name, context)
          end
          puts 'got response attrs'

          h['path'] = context.request.path
          h['url'] = context.request.url
          action_options = h[action.request_method] = {}

          if [ 'GET', 'POST', 'PUT', 'PATCH' ].include? action.request_method
            action_options[:response_attributes] = response_attributes_json
            puts 'set response attrs'
            action_options[:relationships] = self.class.relationships.map(&:options_json)
            puts 'set relationships'
          end

          if [ 'POST', 'PUT', 'PATCH' ].include? action.request_method
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
