module JSONAPIonify::Api
  module Resource::Builders
    class RelationshipsBuilder < FieldsBuilder

      delegate :relationships, to: :resource, prefix: true

      private

      def build_default
        resource_relationships.each_with_object(Objects::Relationships.new) do |relationship, attrs|
          unless relationship.hidden_for_action?(action_name)
            attrs[relationship.name] = build_relationship(relationship)
          end
        end
      end

      def build_sparce
        resource_fields.each_with_object(Objects::Relationships.new) do |field, attrs|
          relationship = resource_relationships.find { |rel| rel.name = field.name.to_sym }
          attrs[field] = build_relationship(relationship) if relationship
        end
      end

      def build_relationship(relationship)
        RelationshipBuilder.build(
          resource,
          relationship: relationship,
          context: context,
          instance: instance
        )
      end

    end
  end
end
