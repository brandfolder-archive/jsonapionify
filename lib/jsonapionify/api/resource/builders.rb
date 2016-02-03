module JSONAPIonify::Api
  module Resource::Builders
    extend ActiveSupport::Concern

    module ClassMethods
      def build_resource(request, instance, fields: api.fields, relationships: true, links: true)
        return nil unless instance
        resource_url = build_url(request, instance)
        id           = build_id(instance)
        JSONAPIonify::Structure::Objects::Resource.new.tap do |resource|
          resource[:id]   = id
          resource[:type] = type

          resource[:attributes]    = fields[type.to_sym].each_with_object(JSONAPIonify::Structure::Objects::Attributes.new) do |member, attributes|
            attributes[member.to_sym] = instance.public_send(member)
          end

          resource[:links]         = JSONAPIonify::Structure::Objects::Links.new(
            self: resource_url
          ) if links

          resource[:relationships] = relationship_definitions.each_with_object(JSONAPIonify::Structure::Maps::Relationships.new) do |rel, hash|
            hash[rel.name] = build_relationship(request, instance, rel.name)
          end if relationships
        end
      end

      def build_resource_identifier(instance)
        JSONAPIonify::Structure::Objects::ResourceIdentifier.new(
          id:   build_id(instance),
          type: type.to_s
        )
      end

      def build_collection(request, collection, fields: api.fields, relationships: false)
        collection.each_with_object(JSONAPIonify::Structure::Collections::Resources.new) do |instance, resources|
          resources << build_resource(request, instance, fields: fields, relationships: relationships)
        end
      end

      def build_identifier_collection(collection)
        collection.each_with_object(JSONAPIonify::Structure::Collections::ResourceIdentifiers.new) do |instance, resource_identifiers|
          resource_identifiers << build_resource_identifier(instance)
        end
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
        URI.parse(request.root_url).tap do |uri|
          uri.path      =
            if instance
              File.join(uri.path, type, build_id(instance))
            else
              File.join(request.root_url, type)
            end
          sticky_params = self.sticky_params(request.params)
          uri.query     = sticky_params.to_param if sticky_params.present?
        end.to_s
      end

      def build_id(instance)
        instance.send(id_attribute).to_s
      end
    end

    included do
      delegate *(ClassMethods.instance_methods - JSONAPIonify::Api::Resource::Builders.instance_methods), to: :class
    end

  end
end
