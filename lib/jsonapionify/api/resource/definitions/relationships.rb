module JSONAPIonify::Api
  module Resource::Definitions::Relationships

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_array_attribute :relationship_definitions
      end
    end

    def relates_to_many(name, **opts, &block)
      define_relationship(name, Relationship::Many, **opts, &block)
    end

    def relates_to_one(name, **opts, &block)
      opts[:resource] ||= name.to_s.pluralize.to_sym
      define_relationship(name, Relationship::One, **opts, &block)
    end

    def define_relationship(name, klass, **opts, &block)
      const_name = name.to_s.camelcase + 'Relationship'
      remove_const(const_name) if const_defined? const_name
      klass.new(self, name, **opts, &block).tap do |new_relationship|
        relationship_definitions.delete new_relationship
        relationship_definitions << new_relationship
      end
    end

    def relationships
      relationship_definitions
    end

    def relationship(name)
      name       = name.to_sym
      const_name = name.to_s.camelcase + 'Relationship'
      return const_get(const_name, false) if const_defined? const_name
      relationship_definition = relationship_definitions.find { |rel| rel.name == name }
      raise Errors::RelationshipNotFound, "Relationship not found: #{name}" unless relationship_definition
      const_set const_name, relationship_definition.resource_class
    end

  end
end
