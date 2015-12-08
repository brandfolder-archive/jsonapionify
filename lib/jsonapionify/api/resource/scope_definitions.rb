module JSONAPIonify::Api
  module Resource::ScopeDefinitions
    def scope(&block)
      define_singleton_method(:current_scope) do
        block.call
      end
      context :scope do
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
  end
end
