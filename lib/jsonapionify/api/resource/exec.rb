module JSONAPIonify::Api
  module Resource::Exec
    using JSONAPIonify::DestructuredProc

    def halt
      # Don't Halt
    end

    def exec(&block)
      instance_exec @__context, &block.destructure
    end
  end
end
