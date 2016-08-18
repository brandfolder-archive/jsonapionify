require 'possessive'
require 'active_support/core_ext/array/wrap'

module JSONAPIonify::Api
  module Resource::Definitions::Actions
    using JSONAPIonify::DestructuredProc
    NoActionError = Class.new NotImplementedError
    NoRelationshipError = Class.new NotImplementedError

    DEFAULT_SAVE_COMMIT = proc do |instance:, request_attributes:, request_relationships:|
      # Assign the attributes
      request_attributes.each do |key, value|
        instance.send "#{key}=", value
      end

      # Assign the relationships
      request_relationships.each do |key, value|
        instance.send "#{key}=", value
      end

      # Save the instance
      instance.save if instance.respond_to? :save
    end

    DEFAULT_DELETE_COMMIT = proc do |instance:|
      instance.respond_to?(:destroy) ? instance.destroy : instance.respond_to?(:delete) ? instance.delete : nil
    end

    INSTANCE_RESPONSE = proc do |context, instance:, response_object:, builder: nil|
      response_object[:data] = build_resource(context: context, instance: instance, &builder)
      response_object.to_json
    end

    CREATE_RESPONSE = proc do |context, instance:, response_object:, builder: nil, response_headers:|
      instance_exec(context, instance: instance, response_object: response_object, builder: builder, &INSTANCE_RESPONSE).tap do
        response_headers['Location'] = response_object[:data][:links][:self]
      end
    end

    COLLECTION_RESPONSE = proc do |context, response_collection:, links:, response_object:, builder: nil, nested_request: false|
      response_object[:data] = build_resource_collection(
        context: context,
        collection: response_collection,
        include_cursors: (links.keys & [:first, :last, :next, :prev]).present?,
        &builder
      )
      response_object.to_json unless nested_request
    end

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_array_attribute :action_definitions
      end
    end

    def list(**options, &block)
      define_action(:list, 'GET', **options, cacheable: true, &block).tap do |action|
        action.response(status: 200, &COLLECTION_RESPONSE)
      end
    end

    def create(**options, &block)
      block ||= DEFAULT_SAVE_COMMIT
      define_action(:create, 'POST', '', **options, cacheable: false, &block).tap do |action|
        action.response(status: 201, &CREATE_RESPONSE)
      end
    end

    def read(**options, &block)
      define_action(:read, 'GET', '/{id}', **options, cacheable: true, &block).tap do |action|
        action.response(status: 200, &INSTANCE_RESPONSE)
      end
    end

    def update(**options, &block)
      block ||= DEFAULT_SAVE_COMMIT
      define_action(:update, 'PATCH', '/{id}', **options, cacheable: false, &block).tap do |action|
        action.response(status: 200, &INSTANCE_RESPONSE)
      end
    end

    def delete(**options, &block)
      block ||= DEFAULT_DELETE_COMMIT
      define_action(:delete, 'DELETE', '/{id}', **options, cacheable: false, body: false, &block).tap do |action|
        action.response(status: 204)
      end
    end

    def call(request)
      self.new(request: request).call
    end

    def define_action(name, *args, **options, &block)
      UnboundAction.new(name, *args, **options, &block).tap do |new_action|
        action_definitions.delete new_action
        action_definitions << new_action
      end
    end

    def remove_action(*names)
      action_definitions.delete_if do |action_definition|
        names.include? action_definition.name
      end
    end

    def call_action(name, request, context_overrides: {})
      new(request: request, action: action(name), context_overrides: context_overrides).call
    end

    def action(name)
      actions.find { |action| action.name == name }
    end

    def actions
      return [] if action_definitions.blank?
      action_definitions.select do |action|
        action.only_associated == false ||
          (respond_to?(:rel) && action.only_associated == true)
      end
    end

    def documented_actions
      api.eager_load
      relationships = descendants.select { |descendant| descendant.respond_to? :rel }
      rels          = relationships.each_with_object([]) do |rel, ary|
        rel.actions.each do |action|
          ary << [action, "#{rel.rel.owner.type}/{id}", [rel, rel.rel.name, false, "#{action.name} #{rel.rel.owner.type.singularize.possessive} #{rel.rel.name}"]]
        end
      end
      actions.map do |action|
        [action, '', [self, type, true, "#{action.name} #{type}"]]
      end + rels
    end

    def base_path(prepend: '/')
      File.join prepend, type || ''
    end

  end
end
