require 'active_support/core_ext/array/wrap'

module JSONAPIonify::Api
  module Resource::ActionDefinitions
    ActionNotFound = Class.new StandardError

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_array_attribute :action_definitions
        inherited_hash_attribute :callbacks

        def self.inherited(subclass)
          super
          callbacks.each do |action_name, klass|
            subclass.callbacks[action_name] = Class.new klass
          end
        end
      end
    end

    def index(**options, &block)
      define_action(:index, 'GET', **options, &block).tap do |action|
        action.response status: 200 do |context|
          context.response_object[:data] = build_collection(context.request, context.paginated_collection, fields: context.fields)
          context.meta[:total_count]     = context.collection.count
          context.response_object.to_json
        end
      end
    end

    def create(**options, &block)
      define_action(:create, 'POST', **options, &block).tap do |action|
        action.response status: 201 do |context|
          context.response_object[:data] = build_resource(context.request, context.instance, fields: context.fields)
          context.response_object.to_json
        end
      end
    end

    def read(**options, &block)
      define_action(:read, 'GET', '/:id', **options, &block).tap do |action|
        action.response status: 200 do |context|
          context.response_object[:data] = build_resource(context.request, context.instance, fields: context.fields)
          context.response_object.to_json
        end
      end
    end

    def update(**options, &block)
      define_action(:update, 'PATCH', '/:id', **options, &block).tap do |action|
        action.response status: 200 do |context|
          context.response_object[:data] = build_resource(context.request, context.instance, fields: context.fields)
          context.response_object.to_json
        end
      end
    end

    def delete(**options, &block)
      define_action(:delete, 'DELETE', '/:id', **options, &block).tap do |action|
        action.response status: 204
      end
    end

    def process(request)
      if (action = find_supported_action(request))
        action.call(self, request)
      elsif (rel = find_supported_relationship(request))
        relationship(rel.name).process(request)
      else
        Action::NotFound.call(self, request)
      end
    end

    def before(action_name, &block)
      callbacks_for(action_name).before_request(&block)
    end

    def callbacks_for(action_name)
      resource               = self
      callbacks[action_name] ||= Class.new do
        def self.context(*)
        end

        include Resource::ErrorHandling

        define_singleton_method(:error_definitions) do
          resource.error_definitions
        end

        include JSONAPIonify::Callbacks
        define_callbacks :request
      end
    end

    def define_action(*args, **options, &block)
      Action.new(*args, **options, &block).tap do |new_action|
        action_definitions.delete new_action
        action_definitions << new_action
      end
    end

    def find_supported_action(request)
      action_definitions.find do |action_definition|
        action_definition.supports?(request, base_path, path_name, supports_path?)
      end
    end

    def find_supported_relationship(request)
      relationship_definitions.find do |rel|
        relationship(rel.name).find_supported_action(request)
      end
    end

    def remove_action(*names)
      action_definitions.delete_if do |action_definition|
        names.include? action_definition.name
      end
    end

    private

    def base_path
      ''
    end

    def supports_path?
      true
    end

    def path_name
      type.to_s
    end
  end
end
