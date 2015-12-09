module JSONAPIonify::Api
  class Relationship::One < Relationship

    prepend_class do
      remove_action :index

      define_singleton_method(:show) do |**options, &block|
        define_action(:show_relationship, **options, &block).response status: 200 do
          output_object[:data] = build_resource(instance)
          meta[:collection]    = self.class.get_url request.root_url
          output_object.to_json
        end
      end

      if rel.associate
        define_singleton_method(:replace) do |**options, &block|
          define_action(:replace_relationship, **options, &block).response status: 200 do
            output_object[:data] = build_resource(instance)
            meta[:collection]    = self.class.get_url request.root_url
            output_object.to_json
          end
        end
      end

      context :instance do |request|
        rel.owner.new(request).instance.send(rel.name)
      end

      show
      if rel.associate
        replace
      end
    end
  end
end
