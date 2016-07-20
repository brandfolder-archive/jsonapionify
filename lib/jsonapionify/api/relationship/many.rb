module JSONAPIonify::Api
  class Relationship::Many < Relationship
    using JSONAPIonify::DestructuredProc

    DEFAULT_REPLACE_COMMIT = proc { |scope:, request_instances:|
      to_add    = request_instances - scope
      to_delete = scope - request_instances
      to_delete.each { |instance| scope.delete(instance) }
      scope.concat to_add
    }

    DEFAULT_ADD_COMMIT = proc { |scope:, request_instances:|
      scope.concat request_instances
    }

    DEFAULT_REMOVE_COMMIT = proc { |scope:, request_instances:|
      request_instances.each { |instance| scope.delete(instance) }
    }

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
        define_action(:show, 'GET', **options, &block).response status: 200 do |collection:, response_object:|
          response_object[:data] = build_resource_identifier_collection(collection: collection)
          response_object.to_json
        end
      end

      define_singleton_method(:replace) do |content_type: nil, callbacks: true, &block|
        block ||= DEFAULT_REPLACE_COMMIT
        options = {
          content_type:  content_type,
          callbacks:     callbacks,
          cacheable:     false,
          prepend:       'relationships',
          example_input: :resource_identifier
        }
        define_action(:replace, 'PATCH', **options, &block).response status: 200 do |collection:, response_object:|
          response_object[:data] = build_resource_identifier_collection(collection: collection)
          response_object.to_json
        end
      end

      define_singleton_method(:add) do |content_type: nil, callbacks: true, &block|
        block ||= DEFAULT_ADD_COMMIT
        options = {
          content_type:  content_type,
          callbacks:     callbacks,
          cacheable:     false,
          prepend:       'relationships',
          example_input: :resource_identifier
        }
        define_action(:add, 'POST', **options, &block).response status: 200 do |collection:, response_object:|
          response_object[:data] = build_resource_identifier_collection(collection: collection)
          response_object.to_json
        end
      end

      define_singleton_method(:remove) do |content_type: nil, callbacks: true, &block|
        block ||= DEFAULT_REMOVE_COMMIT
        options           = {
          content_type:  content_type,
          callbacks:     callbacks,
          cacheable:     false,
          prepend:       'relationships',
          example_input: :resource_identifier
        }
        options[:prepend] = 'relationships'
        define_action(:remove, 'DELETE', **options, &block).response status: 200 do |collection:, response_object:|
          response_object[:data] = build_resource_identifier_collection(collection: collection)
          response_object.to_json
        end
      end

      context :scope do |context, owner:|
        instance_exec(rel.name, owner, context, &rel.resolve.destructure)
      end

      after :commit_add, :commit_remove, :commit_replace do |owner:|
        if defined?(ActiveRecord) && owner.is_a?(ActiveRecord::Base)
          # Collect Errors
          if owner.errors.present?
            owner.errors.messages.each do |attr, messages|
              messages.each do |message|
                error :invalid_attribute, attr, message
              end
            end
          end
        end
      end

      list
      show
    end
  end
end
