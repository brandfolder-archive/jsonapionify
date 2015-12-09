module JSONAPIonify::Api
  module Resource::Builders
    extend ActiveSupport::Concern

    module ClassMethods
      def build_resource(request, instance)
        resource_url = build_url(request, instance)
        id           = build_id(instance)
        JSONAPIonify::Structure::Objects::Resource.new(
          id:            id,
          type:          type,
          attributes:    attributes.select(&:read?).each_with_object({}) do |member, attributes|
            attributes[member.name] = instance.public_send(member.name)
          end,
          links:         JSONAPIonify::Structure::Objects::Links.new(
            self: resource_url
          ),
          relationships: relationship_definitions.each_with_object(JSONAPIonify::Structure::Maps::Relationships.new) do |rel, hash|
            hash[rel.name] = build_relationship(request, instance, rel.name)
          end
        )
      end

      def build_relationship(request, instance, name, links: true, data: false)
        resource_url = build_url(request, instance)
        relationship = self.relationship(name)
        JSONAPIonify::Structure::Objects::Relationship.new.tap do |rel|
          rel[:links] = relationship.build_links(resource_url) if links
          if data
            rel[:data] =
              if relationship < Resource::RelationshipToMany
                instance.send(name).map do |child|
                  relationship.build_resource_identifier(child)
                end
              elsif relationship < Resource::RelationshipToOne
                value = instance.send(name)
                relationship.build_resource_identifier value if value
              end
          end
        end
      end

      def build_url(request, instance = nil)
        if instance
          File.join(request.root_url, type, build_id(instance))
        else
          File.join(request.root_url, type)
        end
      end

      def build_id(instance)
        instance.send(id_attribute).to_s
      end

      def build_resource_identifier(instance)
        JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
          id:   build_id(instance),
          type: type.to_s
        )
      end
    end

    included do
      delegate *(ClassMethods.instance_methods - JSONAPIonify::Api::Resource::Builders.instance_methods), to: :class
    end

    def build_url(instance)
      self.class.build_url(request, instance)
    end

    def build_resource(instance)
      self.class.build_resource(request, instance)
    end

    def response_json
      @response_json ||= JSONAPIonify.new_object
    end

  end
end