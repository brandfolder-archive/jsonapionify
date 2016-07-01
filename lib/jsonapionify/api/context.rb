module JSONAPIonify::Api
  class Context
    using JSONAPIonify::DestructuredProc

    def initialize(readonly: false, persisted: false, existing_context: nil, &block)
      @readonly         = readonly
      @persisted        = persisted
      @existing_context = existing_context
      @block            = block || proc {}
    end

    def call(instance, delegate)
      existing_context = @existing_context || proc {}
      existing_block   = proc { existing_context.call(instance, delegate) }
      begin
        instance.instance_exec(delegate, existing_block, &@block.destructure(0))
      rescue => e
        e.backtrace.unshift @block.source_location.join(':') + ":in (context)"
        raise e
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
