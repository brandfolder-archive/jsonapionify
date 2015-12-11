module JSONAPIonify::Api
  class Relationship::Many < Relationship

    prepend_class do
      rel = self.rel
      remove_action :read

      define_singleton_method(:show) do |**options, &block|
        define_action(:show_relationship, **options, &block).response status: 200 do |context|
          context.response_object[:data] = build_identifier_collection(context.collection)
          context.meta[:total_count]     = context.collection.count
          context.response_object.to_json
        end
      end

      if rel.associate

        define_singleton_method(:replace) do |**options, &block|
          define_action(:replace_relationship, **options, &block).response status: 200 do |context|
            context.response_object[:data] = build_identifier_collection(context.collection)
            context.meta[:total_count]     = context.collection.count
            context.response_object.to_json
          end
        end

        define_singleton_method(:update) do |**options, &block|
          define_action(:update_relationship, **options, &block).response status: 200 do |context|
            context.response_object[:data] = build_identifier_collection(context.collection)
            context.meta[:total_count]     = context.collection.count
            context.response_object.to_json
          end
        end

        define_singleton_method(:remove) do |**options, &block|
          define_action(:remove_relationship, **options, &block).response status: 200 do |context|
            context.response_object[:data] = build_identifier_collection(context.collection)
            context.meta[:total_count]     = context.collection.count
            context.response_object.to_json
          end
        end

      end

      context :scope do |context|
        context.owner_context.instance.send(rel.name)
      end

      show
      if rel.associate
        replace
        update
        remove
      end
    end
  end
end