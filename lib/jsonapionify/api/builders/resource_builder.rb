module JSONAPIonify::Api
  module Resource::Builders
    class ResourceBuilder
      include JSONAPIonify::Structure
      delegate :attributes, :relationships, :type, to: :resource, prefix: true
      delegate :params, :includes, :fields, :action_name, :request, to: :context

      attr_reader :resource, :instance, :context, :links, :include_cursor, :block

      def initialize(resource, instance:, context:, links: true, include_cursor: false, &block)
        @resource = resource
        @context = context
        @instance = instance
        @links = links
        @include_cursor = include_cursor
        @example_id = resource.generate_id
        @block = block
      end

      def build
        return nil unless instance
        Objects::Resource.new.tap do |resource|
          resource[:type] = resource_type
          (id = build_id).present? && resource[:id] = id
          (attributes = build_attributes).present? && resource[:attributes] = attributes
          (relationships = build_relationships).present? && resource[:relationships] = relationships
          (links = build_links).present? && resource[:links] = links
          (meta = build_meta).present? && resource[:meta] = meta
        end
      end

      def build_identifier
        return unless instance
        Structure::Objects::ResourceIdentifier.new.tap do |resource_identifier|
          resource[:type] = resource_type
          (id = build_id).present? && resource[:id] = id
        end
      end

      private

      def resource_fields
        fields[type] || {}
      end

      def build_url
        URI.parse(request.root_url).tap do |uri|
          uri.path      = File.join uri.path, type, build_id
          sticky_params = resource.sticky_params(context.params)
          uri.query     = sticky_params.to_param if sticky_params.present?
        end.to_s
      end

      def build_id
        instance.send(resource.id_attribute).to_s
      end

      def build_attributes
        fields.nil? ? build_default_attributes : build_sparce_attributes
      end

      def build_default_attributes
        resource_attributes.each_with_object(Objects::Attributes.new) do |attribute, attrs|
          if attribute.supports_read_for_action?(action_name, context) && !attribute.hidden_for_action?(action_name)
            attrs[field] = attribute.resolve(instance, context, example_id: example_id)
          end
        end
      end

      def build_sparce_attributes
        resource_fields.each_with_object(Objects::Attributes.new) do |field, attrs|
          attribute = resource_attributes.find { |attr| attr.name = field.name.to_sym }
          if attribute&.supports_read_for_action?(action_name, context)
            attrs[field] = attribute.resolve(instance, context, example_id: example_id)
          end
        end
      end

      def build_relationships
        fields.nil? ? build_default_relationships : build_sparce_relationships
      end

      def build_default_relationships
        resource_relationships.each_with_object(Objects::Attributes.new) do |relationship, attrs|
          unless relationship.hidden_for_action?(action_name)
            attrs[field] = build_relationship(relationship)
          end
        end
      end

      def build_sparce_relationships
        resource_fields.each_with_object(Objects::Attributes.new) do |field, attrs|
          relationship = resource_relationships.find { |rel| rel.name = field.name.to_sym }
          if relationship
            attrs[field] = build_relationship(relationship)
          end
        end
      end

      def build_relationship(relationship)
        relationship = self.relationship(name)
        JSONAPIonify::Objects::Relationship.new.tap do |rel|
          rel[:links] = relationship.build_links(build_url)
          rel[:data] = build_relationship_data(relationship) if includes.present?
        end
      end

      def build_relationship_data(relationship)
        resolution = instance.send(name)
        case relationship
        when Relationship::Many
          resolution.map do |child|
            relationship.build_resource_identifier(child)
          end
        when Relationship::One
          relationship.build_resource_identifier rel
        end
      end

      def build_links
        Objects::Links.new(
          cursor: build_cursor
        )
      end

      def build_meta
        Objects::Meta.new(
          cursor: build_cursor
        )
      end

      def build_cursor
        sort_string        = params['sort']
        sort_fields        = sort_fields_from_sort_string(sort_string)
        attrs_with_values  = sort_fields.each_with_object({}) do |field, hash|
          hash[field.name] = instance.send(field.name)
        end
        Base64.urlsafe_encode64(JSON.dump(
          {
            t: type,
            s: sort_string,
            a: attrs_with_values
          }
        ))
      end
    end
  end
end
