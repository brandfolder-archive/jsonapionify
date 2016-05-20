module JSONAPIonify::Api
  module Attribute::Documentation
    def options_json_for_action(action_name, context)
      {
        name:        @name,
        type:        @type.to_s,
        description: JSONAPIonify::Documentation.onelinify_markdown(description),
        example:     example(context.resource.class.generate_id)
      }.tap do |opts|
        opts[:not_null] = true if @type.not_null?
        opts[:required] = true if required_for_action?(action_name, context)
      end
    end

    def documentation_object
      OpenStruct.new(
        name:        name,
        type:        type.name,
        required:    required ? Array.wrap(required).join(', ') : false,
        description: JSONAPIonify::Documentation.render_markdown(description),
        allow:       allow
      )
    end
  end
end
