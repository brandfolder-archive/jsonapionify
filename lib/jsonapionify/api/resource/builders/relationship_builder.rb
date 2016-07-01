module JSONAPIonify::Api
  module Resource::Builders
    class RelationshipBuilder < BaseBuilder
      include IdentityHelper
      delegate :type, to: :resource, prefix: true
      delegate :request, :includes, to: :context

      attr_reader :relationship, :related_resource, :context, :instance

      def initialize(resource, relationship:, context:, instance:)
        super(resource)
        @relationship = relationship
        @context = context
        @instance = instance
        @related_resource = resource.relationship(relationship.name)
      end

      def build
        Objects::Relationship.new.tap do |rel|
          rel[:links] = related_resource.build_links(build_url)
          rel[:data] = build_data if includes.present?
        end
      end

      private

      def build_data
        rel_resource = resource.relationship(relationship.name)
        case relationship
        when Relationship::Many
          resolution.map do |child|
            rel_resource.build_resource_identifier(instance: child)
          end
        when Relationship::One
          rel_resource.build_resource_identifier instance: resolution
        end
      end

      def resolution
        instance.instance_exec(
          relationship.name,
          instance,
          context,
          &relationship.resolve
        )
      end

    end
  end
end
