module JSONAPIonify::Api
  module Resource::ScopeDefinitions
    def scope(&block)
      context :scope do
        block.call
      end
    end

    def instance(&block)
      context :instance do |_, context|
        block.call(context[:scope], context[:id])
      end
    end

    def collection(&block)
      context :collection do |_, context|
        block.call(context[:scope], context)
      end
    end

    def new_instance(&block)
      context :new_instance do |_, context|
        proc do |*args|
          block.call(context[:scope], context, *args)
        end
      end
    end
  end
end
