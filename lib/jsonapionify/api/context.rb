module JSONAPIonify::Api
  class Context

    def initialize(readonly: false, persisted: false, existing_context: nil, &block)
      @readonly         = readonly
      @persisted        = persisted
      @existing_context = existing_context
      @block            = block || proc {}
    end

    def call(instance, delegate)
      existing_context = @existing_context || proc {}
      existing_block   = proc { existing_context.call(instance, delegate) }
      instance.instance_exec(delegate, existing_block, **delegate.kwargs(@block), &@block)
    end

    def readonly?
      !!@readonly
    end

    def persisted?
      !!@persisted
    end

  end
end
