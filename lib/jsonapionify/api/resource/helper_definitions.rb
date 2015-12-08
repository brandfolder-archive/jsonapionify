module JSONAPIonify::Api
  module Resource::HelperDefinitions
    def context(name, &block)
      self.context_definitions = self.context_definitions.merge name.to_sym => block
      define_method(name) do
        @context.public_send(name)
      end

      define_method("#{name}=") do |value|
        @context.public_send("#{name}=", value)
      end
    end

    def header(name, &block)
      self.header_definitions = self.header_definitions.merge name.to_sym => block
    end

    def helper(name, &block)
      # self.context_definitions = self.context_definitions.merge name.to_sym => block
      define_method(name, &block)
    end

    def context_definitions=(hash)
      @context_definitions = hash
    end

    def context_definitions
      @context_definitions ||= {}
      if superclass.respond_to?(:context_definitions)
        superclass.context_definitions.merge(@context_definitions)
      else
        @context_definitions
      end
    end

    def header_definitions=(hash)
      @header_definitions = hash
    end

    def header_definitions
      @header_definitions ||= {}
      if superclass.respond_to?(:header_definitions)
        superclass.header_definitions.merge(@header_definitions)
      else
        @header_definitions
      end
    end
  end
end