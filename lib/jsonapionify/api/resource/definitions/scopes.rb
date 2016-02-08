module JSONAPIonify::Api
  module Resource::Definitions::Scopes

    def scope(&block)
      define_singleton_method(:current_scope) do
        Object.new.instance_eval(&block)
      end
      context :scope do
        self.class.current_scope
      end
    end

    alias_method :resource_class, :scope

    def instance(&block)
      define_singleton_method(:find_instance) do |id, context = nil|
        Object.new.instance_exec(current_scope, id, context, &block)
      end
      context :instance do |context|
        self.class.find_instance(context.id, context)
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
