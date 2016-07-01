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
      context :instance, persisted: true do |context, scope:, id:|
        instance_exec(scope, id, context, &block)
      end
    end

    def collection(&block)
      context :collection do |context, scope:, includes:|
        collection = Object.new.instance_exec(scope, context, &block)

        # Compute includes manipulations
        self.class.include_definitions.select do |relationship, _|
          includes.keys.include? relationship.to_s
        end.reduce(collection) do |lv, (name, include_block)|
          lv.instance_exec(lv, includes[name.to_s], &include_block)
        end

        # TODO: Compute field manipulations

        # TODO: Compute param manipulations
      end
    end

    def new_instance(&block)
      define_singleton_method(:build_instance) do
        Object.new.instance_exec(current_scope, &block)
      end
      context :new_instance, persisted: true, readonly: true do |context, scope:|
        Object.new.instance_exec(scope, context, &block)
      end
    end
  end
end
