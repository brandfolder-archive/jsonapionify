module JSONAPIonify::Api
  module Resource::Builders
    class ResourceBuilder < ResourceIdentifierBuilder
      delegate :attributes, :relationships, :type, :relationship, to: :resource, prefix: true
      delegate :params, :includes, :fields, :action_name, :request, to: :context

      attr_reader :context, :links, :include_cursor, :block

      def initialize(resource, context:, links: true, include_cursor: false, **opts, &block)
        super(resource, **opts)
        @context = context
        @links = links
        @include_cursor = include_cursor
        @block = block
      end

      def build
        return nil unless instance
        Objects::Resource.new.tap do |resource|
          resource[:type] = resource_type
          (id = build_id) && resource[:id] = id
          (attributes = build_attributes).present? && resource[:attributes] = attributes
          (relationships = build_relationships).present? && resource[:relationships] = relationships
          (links = build_links).present? && resource[:links] = links
          (meta = build_meta).present? && resource[:meta] = meta
        end
      end

      private

      def build_attributes
        AttributesBuilder.build(
          resource,
          instance:   instance,
          context:    context,
          example_id: example_id
        )
      end

      def build_relationships
        RelationshipsBuilder.build(
          resource,
          instance:   instance,
          context:    context,
          example_id: example_id
        )
      end

      def build_links
        return unless links
        Objects::Links.new(self: build_url)
      end

      def build_meta
        Objects::Meta.new.tap do |meta|
          (cursor = build_cursor).present? && meta[:cursor] = cursor
        end
      end

      def build_cursor
        return unless include_cursor
        CursorBuilder.build(resource, instance: instance, context: context)
      end
    end
  end
end
