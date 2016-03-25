module JSONAPIonify::Api
  module Resource::Definitions::Scopes

    def scope(&block)
      define_singleton_method(:current_scope) do
        instance_exec(OpenStruct.new, &block)
      end
      context :scope do |context|
        instance_exec(context, &block)
      end
    end

    alias_method :resource_class, :scope

    def instance(&block)
      define_singleton_method(:find_instance) do |id|
        instance_exec(current_scope, id, OpenStruct.new, &block)
      end
      context :instance do |context|
        instance_exec(context.scope, context.id, context, &block)
      end
    end

    def collection(&block)
      context :collection do |context|
        Object.new.instance_exec(context.scope, context, &block)
      end
    end

    def new_instance(&block)
      define_singleton_method(:build_instance) do
        Object.new.instance_exec(current_scope, &block)
      end
      context :new_instance do |context|
        Object.new.instance_exec(context.scope, context, &block)
      end
    end
  end
end
