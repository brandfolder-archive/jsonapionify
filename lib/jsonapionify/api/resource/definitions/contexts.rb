module JSONAPIonify::Api
  module Resource::Definitions::Contexts

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :context_definitions
      end
    end

    def context(name, **opts, &block)
      self.context_definitions[name.to_sym] = Context.new(
        name,
        **opts,
        existing_context: self.context_definitions[name.to_sym],
        &block
      )
    end

    def remove_context name
      self.context_definitions.delete(name)
    end

  end
end
