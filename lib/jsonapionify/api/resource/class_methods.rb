module JSONAPIonify::Api
  module Resource::ClassMethods
    NotFoundClass         = Class.new().include(Actions::NotFound)
    MethodNotAllowedClass = Class.new(JSONAPIonify::Api::Resource).include(Actions::MethodNotAllowed)

    # Static Processing
    def process_not_found(req)
      NotFoundClass.new(req).response
    end

    def process_method_not_allowed(req)
      MethodNotAllowedClass.new(req).response
    end

    def set_api(api)
      self.tap do
        define_singleton_method :api do
          api
        end
      end
    end

    def api
      nil
    end

    # Resource Description
    def description(string)
    end

    # Request Internals
    def context(name, &block)
      self.context_definitions = self.context_definitions.merge name.to_sym => block
      define_method(name) do
        @context.public_send(name)
      end

      define_method("#{name}=") do |value|
        @context.public_send("#{name}=", value)
      end
    end

    def header(name, &block)
      self.header_definitions = self.header_definitions.merge name.to_sym => block
    end

    def helper(name, &block)
      # self.context_definitions = self.context_definitions.merge name.to_sym => block
      define_method(name, &block)
    end

    def response(status:, &block)
      define_method(:response) do
        Rack::Response.new.tap do |response|
          response.status = status
          headers.each { |k, v| response[k] = v }
          response.write instance_eval(&block).to_json
        end.finish
      end
    end

    # Errors
    def error(name, &block)
      self.error_definitions = self.error_definitions.merge name.to_sym => block
    end

    def rescue_from(*klasses, error:)
      super *klasses do |exception|
        error(error, exception.message)
      end
    end

    # Fields
    def scope(&block)
      define_singleton_method(:current_scope) do
        block.call
      end
      context :scope do |_|
        current_scope
      end
    end

    def instance(&block)
      define_singleton_method(:find_instance) do |id|
        block.call current_scope, id
      end
      context :instance do |_, context|
        find_instance(context.id)
      end
    end

    def collection(&block)
      context :collection do |_, context|
        block.call(context.scope, context)
      end
    end

    def new_instance(&block)
      context :new_instance do |_, context|
        proc do |*args|
          block.call(context.scope, context, *args)
        end
      end
    end

    def id(sym)
    end

    def field(name, type, description, required: false, read: true, write: true)
    end

    # Associations
    def relates_to_many(name, associate: true, &block)
      relationship_definitions[name] = Class.new(api.resource(name)) do
        instance_eval(&block) if block_given?
        if associate
          related_ids_action = Class.new(self).include(Actions::RelatedIds)
          define_singleton_method
        else
          # Undefine other methods?
        end

      end
    end

    def relates_to_one(name, associate: true)
    end

    # Actions
    def index(&block)
      index_action = Class.new(self).include(Actions::Index)
      define_singleton_method :process_index do |req|
        index_action.new(req).response(&block)
      end

      ids_action = Class.new(self).include(Actions::Ids)
      define_singleton_method :process_ids do |req|
        ids_action.new(req).response(&block)
      end
    end

    def create(&block)
      create_action = Class.new(self).include(Actions::Create)
      define_singleton_method :process_create do |req|
        create_action.new(req).response(&block)
      end
    end

    def read(&block)
      read_action = Class.new(self).include(Actions::Read)
      define_singleton_method :process_read do |req|
        read_action.new(req).response(&block)
      end
    end

    def update(&block)
      update_action = Class.new(self).include(Actions::Update)
      define_singleton_method :process_update do |req|
        update_action.new(req).response(&block)
      end
    end

    def delete(&block)
      delete_action = Class.new(self).include(Actions::Delete)
      define_singleton_method :process_delete do |req|
        delete_action.new(req).response(&block)
      end
    end

    # Relationships
    def relationship(name)

    end

    # Definitions
    def context_definitions=(hash)
      @context_definitions = hash
    end

    def context_definitions
      @context_definitions ||= {}
      if superclass.respond_to?(:context_definitions)
        superclass.context_definitions.merge(@context_definitions)
      else
        @context_definitions
      end
    end

    def header_definitions=(hash)
      @header_definitions = hash
    end

    def header_definitions
      @header_definitions ||= {}
      if superclass.respond_to?(:header_definitions)
        superclass.header_definitions.merge(@header_definitions)
      else
        @header_definitions
      end
    end

    def error_definitions=(hash)
      @error_definitions = hash
    end

    def error_definitions
      @error_definitions ||= {}
      if superclass.respond_to?(:error_definitions)
        superclass.error_definitions.merge(@error_definitions)
      else
        @error_definitions
      end
    end

    def relationship_definitions=(hash)
      @relationship_definitions = hash
    end

    def relationship_definitions
      @relationship_definitions ||= {}
      if superclass.respond_to?(:relationship_definitions)
        superclass.relationship_definitions.merge(@relationship_definitions)
      else
        @relationship_definitions
      end
    end

  end
end