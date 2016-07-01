require 'possessive'
require 'active_support/core_ext/array/wrap'

module JSONAPIonify::Api
  module Resource::Definitions::Actions
    using JSONAPIonify::DestructuredProc
    ActionNotFound = Class.new StandardError

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

    COLLECTION_RESPONSE = proc do |context, response_collection:, links:, response_object:, builder: nil|
      response_object[:data] = build_resource_collection(
        context: context,
        collection: response_collection,
        include_cursors: (links.keys & [:first, :last, :next, :prev]).present?,
        &builder
      )
      response_object.to_json
    end

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        define_callbacks(
          :request,
          :exception,
          :response,
          :list,    :commit_list,
          :create,  :commit_create,
          :read,    :commit_read,
          :update,  :commit_update,
          :delete,  :commit_delete,
          :show,    :commit_show,
          :add,     :commit_add,
          :remove,  :commit_remove,
          :replace, :commit_replace
        )
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
      define_action(:create, 'POST', '', **options, cacheable: false, example_input: :resource, &block).tap do |action|
        action.response(status: 201, &CREATE_RESPONSE)
      end
    end

    def read(**options, &block)
      define_action(:read, 'GET', '/:id', **options, cacheable: true, &block).tap do |action|
        action.response(status: 200, &INSTANCE_RESPONSE)
      end
    end

    def update(**options, &block)
      block ||= DEFAULT_SAVE_COMMIT
      define_action(:update, 'PATCH', '/:id', **options, cacheable: false, example_input: :resource, &block).tap do |action|
        action.response(status: 200, &INSTANCE_RESPONSE)
      end
    end

    def delete(**options, &block)
      block ||= DEFAULT_DELETE_COMMIT
      define_action(:delete, 'DELETE', '/:id', **options, cacheable: false, &block).tap do |action|
        action.response(status: 204)
      end
    end

    def process(request)
      if (action = find_supported_action(request))
        action.call(self, request)
      elsif (rel = find_supported_relationship(request))
        relationship(rel.name).process(request)
      else
        no_action_response(request).call(self, request)
      end
    end

    %i{before after}.each do |cb|
      define_method(cb) do |*action_names, &block|
        return send(:"#{cb}_request", &block) if action_names.blank?
        action_names.each do |action_name|
          send("#{cb}_#{action_name}", &block)
        end
      end
    end

    def define_action(name, *args, **options, &block)
      Action.new(name, *args, **options, &block).tap do |new_action|
        action_definitions.delete new_action
        action_definitions << new_action
      end
    end

    def find_supported_action(request)
      actions.find do |action|
        action.supports?(request, base_path, path_name, supports_path?)
      end
    end

    def no_action_response(request)
      if request_method_actions(request).present?
        Action.error :unsupported_media_type
      elsif self.path_actions(request).present?
        Action.error :forbidden
      else
        Action.error :not_found
      end
    end

    def path_actions(request)
      actions.select do |action|
        action.supports_path?(request, base_path, path_name, supports_path?)
      end
    end

    def request_method_actions(request)
      path_actions(request).select do |action|
        action.supports_request_method?(request)
      end
    end

    def find_supported_relationship(request)
      relationship_definitions.find do |rel|
        relationship = self.relationship(rel.name)
        relationship != self && relationship.path_actions(request).present?
      end
    end

    def remove_action(*names)
      action_definitions.delete_if do |action_definition|
        names.include? action_definition.name
      end
    end

    def call_action(name, request, **context_overrides)
      action(name).call(self, request, **context_overrides)
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
          ary << [action, "#{rel.rel.owner.type}/:id", [rel, rel.rel.name, false, "#{action.name} #{rel.rel.owner.type.singularize.possessive} #{rel.rel.name}"]]
        end
      end
      actions.map do |action|
        [action, '', [self, type, true, "#{action.name} #{type}"]]
      end + rels
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
