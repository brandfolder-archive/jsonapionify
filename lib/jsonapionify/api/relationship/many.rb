module JSONAPIonify::Api
  class Relationship::Many < Relationship

    prepend_class do
      rel = self.rel
      remove_action :read
      class << self
        undef_method :read
      end

      define_singleton_method(:show) do |content_type: nil, callbacks: true, &block|
        options = {
          content_type: content_type,
          callbacks:    callbacks,
          cacheable:    true,
          prepend:      'relationships'
        }
        define_action(:show, 'GET', **options, &block).response status: 200 do |context|
          context.response_object[:data] = build_identifier_collection(context.collection)
          context.response_object.to_json
        end
      end

      define_singleton_method(:replace) do |content_type: nil, callbacks: true, &block|
        options = {
          content_type:  content_type,
          callbacks:     callbacks,
          cacheable:     false,
          prepend:       'relationships',
          example_input: :resource_identifier
        }
        define_action(:replace, 'PATCH', **options, &block).response status: 200 do |context|
          context.owner_context.reset(:instance)
          context.reset(:collection)
          context.response_object[:data] = build_identifier_collection(context.collection)
          context.response_object.to_json
        end
      end

      define_singleton_method(:add) do |content_type: nil, callbacks: true, &block|
        options = {
          content_type:  content_type,
          callbacks:     callbacks,
          cacheable:     false,
          prepend:       'relationships',
          example_input: :resource_identifier
        }
        define_action(:add, 'POST', **options, &block).response status: 200 do |context|
          context.owner_context.reset(:instance)
          context.reset(:collection)
          context.response_object[:data] = build_identifier_collection(context.collection)
          context.response_object.to_json
        end
      end

      define_singleton_method(:remove) do |content_type: nil, callbacks: true, &block|
        options           = {
          content_type:  content_type,
          callbacks:     callbacks,
          cacheable:     false,
          prepend:       'relationships',
          example_input: :resource_identifier
        }
        options[:prepend] = 'relationships'
        define_action(:remove, 'DELETE', **options, &block).response status: 200 do |context|
          context.owner_context.reset(:instance)
          context.reset(:collection)
          context.response_object[:data] = build_identifier_collection(context.collection)
          context.response_object.to_json
        end
      end

      context :scope do |context|
        instance_exec rel.name, context.owner, context, &rel.resolve
      end

      show
    end
  end
end
