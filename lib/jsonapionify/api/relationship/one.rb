module JSONAPIonify::Api
  class Relationship::One < Relationship

    prepend_class do
      rel = self.rel
      remove_action :index

      define_singleton_method(:show) do |**options, &block|
        define_action(:show_relationship, **options, &block).response status: 200 do |context|
          context.response_object[:data] = build_resource_indentifier(context.instance)
          context.response_object.to_json
        end
      end

      if rel.associate
        define_singleton_method(:replace) do |**options, &block|
          define_action(:replace_relationship, **options, &block).response status: 200 do |context|
            context.response_object[:data] = build_resource_indentifier(context.instance)
            context.response_object.to_json
          end
        end
      end

      context :instance do |context|
        context.owner_context.instance.send(rel.name)
      end

      show
      if rel.associate
        replace
      end
    end
  end
end
