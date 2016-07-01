module JSONAPIonify::Api
  module Resource::Builders
    class RelationshipsBuilder < FieldsBuilder

      delegate :relationships, to: :resource, prefix: true
      delegate :includes, to: :context

      private

      def build_default
        resource_relationships.each_with_object(Objects::Relationships.new) do |relationship, attrs|
          if !relationship.hidden_for_action?(action_name) || includes.keys.include?(relationship.name.to_s)
            attrs[relationship.name] = build_relationship(relationship)
          end
        end
      end

      def build_sparce
        (resource_fields + includes.keys).each_with_object(Objects::Relationships.new) do |field, attrs|
          field = field.to_sym
          relationship = resource_relationships.find { |rel| rel.name == field }
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
