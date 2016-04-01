module JSONAPIonify::Api
  module Resource::Builders
    extend ActiveSupport::Concern
    FALSEY_STRINGS = JSONAPIonify::FALSEY_STRINGS
    TRUTHY_STRINGS = JSONAPIonify::TRUTHY_STRINGS
    Structure      = JSONAPIonify::Structure

    module ClassMethods

      def build_resource(
        context,
        instance,
        fields:,
        relationships: true,
        links: true,
        include_cursor: false, &block
      )
        example_id = generate_id
        include_rel_param = context.params['include-relationships']
        relationships     = false if FALSEY_STRINGS.include?(include_rel_param)
        return nil unless instance
        resource_url = build_url(context, instance)
        id           = build_id(instance)
        Structure::Objects::Resource.new.tap do |resource|
          resource[:id]   = id
          resource[:type] = type

          resource[:attributes]    = fields[type.to_sym].each_with_object(
            Structure::Objects::Attributes.new
          ) do |member, attributes|
            attribute = self.attributes.find { |a| a.name == member.to_sym }
            unless attribute.supports_read_for_action?(context.action_name, context)
              error_block =
                context.resource.class.error_definitions[:internal_server_error]
              context.errors.evaluate(
                name,
                error_block:   error_block,
                runtime_block: proc {}
              )
            end
            attributes[member.to_sym] = attribute.resolve(
              instance, context, example_id: example_id
            )
          end

          resource[:links]         = Structure::Objects::Links.new(
            self: resource_url
          ) if links

          resource[:meta]          = {
            cursor: build_cursor_from_instance(context, instance)
          } if include_cursor

          resource[:relationships] = relationship_definitions.each_with_object(
            Structure::Maps::Relationships.new
          ) do |rel, hash|
            hash[rel.name] = build_relationship(context, instance, rel.name)
          end if relationships

          block.call(resource, instance) if block
        end
      end

      def build_resource_identifier(instance)
        Structure::Objects::ResourceIdentifier.new(
          id:   build_id(instance),
          type: type.to_s
        )
      end

      def build_collection(
        context,
        collection,
        fields:,
        include_cursors: false,
        &block
      )
        include_rel_param = context.params['include-relationships']
        relationships     = TRUTHY_STRINGS.include? include_rel_param
        collection.each_with_object(
          Structure::Collections::Resources.new
        ) do |instance, resources|
          resources << build_resource(
            context,
            instance,
            fields:         fields,
            relationships:  relationships,
            include_cursor: include_cursors,
            &block
          )
        end
      end

      def build_cursor_from_instance(context, instance)
        sort_string       = context.params['sort']
        sort_fields       = sort_fields_from_sort_string(sort_string)
        attrs_with_values = sort_fields.each_with_object({}) do |field, hash|
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

      def build_identifier_collection(collection)
        collection.each_with_object(
          JSONAPIonify::Structure::Collections::ResourceIdentifiers.new
        ) do |instance, resource_identifiers|
          resource_identifiers << build_resource_identifier(instance)
        end
      end

      def build_relationship(context, instance, name, links: true, data: false)
        resource_url = build_url(context, instance)
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

      def build_url(context, instance = nil)
        URI.parse(context.request.root_url).tap do |uri|
          uri.path      =
            if instance
              File.join(uri.path, type, build_id(instance))
            else
              File.join(context.request.root_url, type)
            end
          sticky_params = self.sticky_params(context.params)
          uri.query     = sticky_params.to_param if sticky_params.present?
        end.to_s
      end

      def build_id(instance)
        instance.send(id_attribute).to_s
      end
    end

    included do
      delegated_methods = ClassMethods.instance_methods -
        JSONAPIonify::Api::Resource::Builders.instance_methods
      delegate(*delegated_methods, to: :class)
    end

  end
end
