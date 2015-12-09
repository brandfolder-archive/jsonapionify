class JSONAPIonify::Api::Resource
  module RelationshipDefinitions

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_hash_attribute :relationship_definitions
      end
    end

    def relates_to_many(name, associate: true, resource: nil, &block)
      resource                       ||= name
      relationship_definitions[name] = [resource, proc do
        include RelationshipToMany
        instance_eval(&block) if block_given?

        define_singleton_method(:build_links) do |base_url|
          JSONAPIonify::Structure::Maps::RelationshipLinks.new(
            self:    File.join(base_url, 'relationships', name.to_s),
            related: File.join(base_url, name.to_s)
          )
        end

        define_singleton_method(:allow) do
          Array.new.tap do |ary|
            ary << 'read'
            ary << 'write' if associate
          end
        end
      end]
    end

    def relates_to_one(name, associate: true, resource: nil, &block)
      resource                       ||= name
      relationship_definitions[name] = [resource, proc do
        include RelationshipToOne
        instance_eval(&block) if block_given?

        define_singleton_method(:build_links) do |base_url|
          JSONAPIonify::Structure::Maps::RelationshipLinks.new(
            self:    File.join(base_url, 'relationships', name.to_s),
            related: File.join(base_url, name.to_s)
          )
        end

        define_singleton_method(:allow) do
          Array.new.tap do |ary|
            ary << 'read'
            ary << 'write' if associate
          end
        end
      end]
    end

    def relationship(name)
      name       = name.to_sym
      const_name = name.to_s.camelcase + 'Relationship'
      return const_get(const_name) if const_defined? const_name
      raise RelationshipNotDefined, "Relationship not defined: #{name}" unless relationship_defined?(name)
      resource, class_proc = relationship_definitions[name]
      const_set const_name, Class.new(api.resource(resource), &class_proc)
    end

    def relationship_defined?(name)
      !!relationship_definitions[name]
    end

  end
end
