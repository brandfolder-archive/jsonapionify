require 'possessive'
require 'active_support/core_ext/array/wrap'

module JSONAPIonify::Api
  module Resource::Definitions::Actions
    ActionNotFound = Class.new StandardError

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        include JSONAPIonify::Callbacks
        define_callbacks(
          :request, :exception, :response,
          :list, :commit_list,
          :create, :commit_create,
          :read, :commit_read,
          :update, :commit_update,
          :delete, :commit_delete,
          :show, :commit_show,
          :add, :commit_add,
          :remove, :commit_remove,
          :replace, :commit_replace
        )
        inherited_array_attribute :action_definitions
      end
    end

    def list(content_type: nil, only_associated: false, callbacks: true, &block)
      options = {
        content_type:    content_type,
        only_associated: only_associated,
        callbacks:       callbacks,
        cacheable:       true
      }
      define_action(:list, 'GET', **options, &block).tap do |action|
        action.response status: 200 do |context|
          builder                        = context.respond_to?(:builder) ? context.builder : nil
          context.response_object[:data] = build_resource_collection(
            context: context,
            collection: context.response_collection,
            include_cursors: (context.links.keys & [:first, :last, :next, :prev]).present?,
            &builder
          )
          context.response_object.to_json
        end
      end
    end

    def create(content_type: nil, only_associated: false, callbacks: true, &block)
      options = {
        content_type:    content_type,
        only_associated: only_associated,
        callbacks:       callbacks,
        cacheable:       false,
        example_input:   :resource
      }
      define_action(:create, 'POST', **options, &block).tap do |action|
        action.response status: 201 do |context|
          builder                        = context.respond_to?(:builder) ? context.builder : nil
          context.response_object[:data] = build_resource(
            context: context,
            instance: context.instance,
            &builder
          )
          response_headers['Location']   = context.response_object[:data][:links][:self]
          context.response_object.to_json
        end
      end
    end

    def read(content_type: nil, only_associated: false, callbacks: true, &block)
      options = {
        content_type:    content_type,
        only_associated: only_associated,
        callbacks:       callbacks,
        cacheable:       true
      }
      define_action(:read, 'GET', '/:id', **options, &block).tap do |action|
        action.response status: 200 do |context|
          builder                        = context.respond_to?(:builder) ? context.builder : nil
          context.response_object[:data] = build_resource(
            context: context,
            instance: context.instance, &builder
          )
          context.response_object.to_json
        end
      end
    end

    def update(content_type: nil, only_associated: false, callbacks: true, &block)
      options = {
        content_type:    content_type,
        only_associated: only_associated,
        callbacks:       callbacks,
        cacheable:       false,
        example_input:   :resource
      }
      define_action(:update, 'PATCH', '/:id', **options, &block).tap do |action|
        action.response status: 200 do |context|
          builder                        = context.respond_to?(:builder) ? context.builder : nil
          context.response_object[:data] = build_resource(context: context, instance: context.instance,  &builder)
          context.response_object.to_json
        end
      end
    end

    def delete(content_type: nil, only_associated: false, callbacks: true, &block)
      options = {
        content_type:    content_type,
        only_associated: only_associated,
        callbacks:       callbacks,
        cacheable:       false
      }
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
        no_action_response(request).call(self, request)
      end
    end

    def after(*action_names, &block)
      return after_request(&block) if action_names.blank?
      action_names.each do |action_name|
        send("after_#{action_name}", &block)
      end
    end

    def before(*action_names, &block)
      return before_request(&block) if action_names.blank?
      action_names.each do |action_name|
        send("before_#{action_name}", &block)
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
