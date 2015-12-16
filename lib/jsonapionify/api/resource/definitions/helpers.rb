module JSONAPIonify::Api
  module Resource::Definitions::Helpers

    def helper(name, &block)
      define_method(name, &block)
    end

  end
end
