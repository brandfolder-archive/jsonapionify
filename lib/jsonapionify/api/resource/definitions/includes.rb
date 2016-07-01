module JSONAPIonify::Api
  module Resource::Definitions::Includes

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :include_definitions
      end
    end

    def includable(relationship, &block)
      include_definitions[relationship.to_sym] = block
    end

  end
end
