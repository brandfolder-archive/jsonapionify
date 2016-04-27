module JSONAPIonify::Api
  class Context < Struct.new :block, :readonly, :existing_context

    def call(instance, delegate)
      existing_block = proc { existing_context.call(instance, delegate) }
      block = self.block || proc {}
      instance.instance_exec(delegate, existing_block, &block)
    end

    def readonly?
      !!readonly
    end

  end
end
