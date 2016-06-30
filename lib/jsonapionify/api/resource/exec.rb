module JSONAPIonify::Api
  module Resource::Exec
    def halt
      # Don't Halt
    end

    def exec(&block)
      instance_exec @__context, **@__context.kwargs(block), &block
    end
  end
end
