module JSONAPIonify::Api
  class Relationship::One < Relationship

    prepend_class do
      rel = self.rel
      remove_action :list, :create

      class << self
        undef_method :list
      end

      define_singleton_method(:show) do |content_type: nil, callbacks: true, &block|
        options = {
          content_type: content_type,
          callbacks:    callbacks,
          cacheable:    true,
          prepend:      'relationships'
        }
        define_action(:show, 'GET', **options, &block).response status: 200 do |context|
          context.response_object[:data] = build_resource_identifier(context.instance)
          context.response_object.to_json
        end
      end

      define_singleton_method(:replace) do |content_type: nil, callbacks: true, &block|
        options = {
          content_type: content_type,
          callbacks:    callbacks,
          cacheable:    false,
          prepend:      'relationships'
        }
        define_action(:replace, 'PATCH', **options, &block).response status: 200 do |context|
          context.owner_context.reset(:instance)
          context.reset(:instance)
          context.response_object[:data] = build_resource_identifier(context.instance)
          context.response_object.to_json
        end
      end

      context :instance do |context|
        instance_exec rel.name, context.owner, context, &rel.resolve
      end

      show
    end
  end
end
