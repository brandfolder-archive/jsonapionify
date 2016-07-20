module JSONAPIonify::Api
  class Context
    using JSONAPIonify::DestructuredProc

    def initialize(name, readonly: false, persisted: false, existing_context: nil, &block)
      @name             = name.to_sym
      @readonly         = readonly
      @persisted        = persisted
      @existing_context = existing_context
      @block            = block || proc {}
    end

    def call(instance, delegate)
      existing_context = @existing_context || proc {}
      existing_block   = proc { existing_context.call(instance, delegate) }
      JSONAPIonify::CustomRescue.perform(remove: __FILE__, source: @block, formatter: ->(meta) { meta.source_location.join(':') + ":in context: `#{@name}''" }) do
        instance.instance_exec(delegate, existing_block, &@block.destructure(0))
      end
    end

    def readonly?
      !!@readonly
    end

    def persisted?
      !!@persisted
    end

  end
end
