module JSONAPIonify::Api
  module Resource::ScopeDefinitions
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
      define_singleton_method(:find_instance) do |id|
        Object.new.instance_exec(current_scope, id, &block)
      end
      context :instance do |context|
        self.class.find_instance(context.id)
      end
    end

    def collection(&block)
      context :collection do |context|
        Object.new.instance_exec(context.scope, context, &block)
      end
    end

    def new_instance(&block)
      context :new_instance do |context|
        Object.new.instance_exec(context.scope, context, &block)
      end
    end
  end
end
