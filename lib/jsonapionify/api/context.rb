module JSONAPIonify::Api
  class Context < Struct.new :block, :readonly

    def call(instance, delegate)
      block = self.block || proc {}
      instance.instance_exec(delegate, &block)
    end

    def readonly?
      !!readonly
    end

  end
end