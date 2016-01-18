require 'possessive'
require 'active_support/core_ext/array/wrap'

module JSONAPIonify::Api
  module Resource::Definitions::Actions
    ActionNotFound = Class.new StandardError

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        include JSONAPIonify::Callbacks
        define_callbacks :request, :list, :create, :read, :update, :delete,
                         :show, :add, :remove, :replace, :exception
        inherited_array_attribute :action_definitions
      end
    end

    def list(**options, &block)
      define_action(:list, 'GET', **options, &block).tap do |action|
        action.response status: 200 do |context|
          context.response_object[:data] = build_collection(
            context.request,
            context.response_collection,
            fields: context.fields
          )
          context.response_object.to_json
        end
      end
    end

    def index(**options, &block)
      warn 'the `index` action will soon be deprecated, use `list` instead!'
      list(**options, &block)
    end

    def create(**options, &block)
      define_action(:create, 'POST', **options, &block).tap do |action|
        action.response status: 201 do |context|
          context.response_object[:data] = build_resource(context.request, context.instance, fields: context.fields)
          response_headers['Location']   = build_url(context.request, context.instance)
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
      path_actions = self.path_actions(request)
      if request.options? && path_actions.present?
        Action.dummy do
          response_headers['Allow'] = path_actions.map(&:request_method).join(', ')
        end.response(status: 200, accept: '*/*').call(self, request)
      elsif (action = find_supported_action(request))
        action.call(self, request)
      elsif (rel = find_supported_relationship(request))
        relationship(rel.name).process(request)
      else
        no_action_response(request).call(self, request)
      end
    end

    def before(action_name = nil, &block)
      if action_name == :index
        warn 'the `index` action will soon be deprecated, use `list` instead!'
        action_name = :list
      end
      return before_request &block if action_name == nil
      send("before_#{action_name}", &block)
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
        relationship(rel.name).path_actions(request).present?
      end
    end

    def remove_action(*names)
      if names.include? :index
        warn 'the `index` action will soon be deprecated, use `list` instead!'
        names << :list
      end
      action_definitions.delete_if do |action_definition|
        names.include? action_definition.name
      end
    end

    def actions
      return if action_definitions.blank?
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
