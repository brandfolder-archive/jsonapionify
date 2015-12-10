module JSONAPIonify::Api
  module Resource::HelperDefinitions

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes

        inherited_hash_attribute :header_definitions, :context_definitions
      end
    end

    def context(name, readonly: false, &block)
      self.context_definitions[name.to_sym] = block
      define_method(name) do
        @context[name]
      end

      define_method("#{name}=") do |value|
        @context[name] = value
      end unless readonly
    end

    def header(name, &block)
      self.header_definitions = self.header_definitions.merge name.to_sym => block
    end

    def helper(name, &block)
      define_method(name, &block)
    end

  end
end
