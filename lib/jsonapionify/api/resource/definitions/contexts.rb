module JSONAPIonify::Api
  module Resource::Definitions::Contexts

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :context_definitions
      end
    end

    def context(name, readonly: false, &block)
      self.context_definitions[name.to_sym] = Context.new(block, readonly)
    end

  end
end
