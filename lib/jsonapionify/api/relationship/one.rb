module JSONAPIonify::Api
  class Relationship::One < Relationship

    prepend_class do
      rel = self.rel
      remove_action :list, :create
      class << self
        undef_method :list, :create
      end

      define_singleton_method(:show) do |**options, &block|
        options[:prepend] = 'relationships'
        define_action(:show, 'GET', '', nil, :resource_identifier, **options, &block).response status: 200 do |context|
          context.response_object[:data] = build_resource_identifier(context.instance)
          context.response_object.to_json
        end
      end

      define_singleton_method(:replace) do |**options, &block|
        options[:prepend] = 'relationships'
        define_action(:replace, 'PATCH', '', nil, :resource_identifier, **options, &block).response status: 200 do |context|
          context.owner_context.reset(:instance)
          context.reset(:instance)
          context.response_object[:data] = build_resource_identifier(context.instance)
          context.response_object.to_json
        end
      end

      context :instance do |context|
        context.owner_context.instance.send(rel.name)
      end

      show
    end
  end
end
