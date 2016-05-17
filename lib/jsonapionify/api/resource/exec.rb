module JSONAPIonify::Api
  module Resource::Exec
    def exec(&block)
      instance_exec @__context, &block
    end
  end
end
