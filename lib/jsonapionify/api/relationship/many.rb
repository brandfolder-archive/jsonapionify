module JSONAPIonify::Api
  class Relationship::Many < Relationship

    prepend_class do
      remove_action :read

      define_singleton_method(:show) do |**options, &block|
        define_action(:show_relationship, **options, &block).response status: 200 do
          output_object[:data] = paginated_collection.map do |instance|
            build_resource_identifier instance
          end
          meta[:total_count]   = collection.count
          output_object.to_json
        end
      end

      if rel.associate

        define_singleton_method(:replace) do |**options, &block|
          define_action(:replace_relationship, **options, &block).response status: 200 do
            output_object[:data] = paginated_collection.map do |instance|
              build_resource instance
            end
            meta[:total_count]   = collection.count
            output_object.to_json
          end
        end

        define_singleton_method(:update) do |**options, &block|
          define_action(:update_relationship, **options, &block).response status: 200 do
            output_object[:data] = paginated_collection.map do |instance|
              build_resource instance
            end
            meta[:total_count]   = collection.count
            output_object.to_json
          end
        end

        define_singleton_method(:remove) do |**options, &block|
          define_action(:remove_relationship, **options, &block).response status: 200 do
            output_object[:data] = paginated_collection.map do |instance|
              build_resource instance
            end
            meta[:total_count]   = collection.count
            output_object.to_json
          end
        end

      end

      context :scope do |request|
        rel.owner.new(request).instance.send(rel.name)
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