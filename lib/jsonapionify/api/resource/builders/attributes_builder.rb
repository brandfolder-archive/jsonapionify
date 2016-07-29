module JSONAPIonify::Api
  module Resource::Builders
    class AttributesBuilder < FieldsBuilder

      attr_reader :write

      def initialize(*args, write: false, **opts)
        super(*args, **opts)
        @write = write
      end

      delegate :attributes, to: :resource, prefix: true

      private

      def build_default
        resource_attributes.each_with_object(Objects::Attributes.new) do |attribute, attrs|
          if !attribute.hidden_for_action?(action_name)
            build_attribute(attribute, attrs)
          end
        end
      end

      def build_sparce
        resource_fields.each_with_object(Objects::Attributes.new) do |field, attrs|
          field = field.to_sym
          attribute = resource_attributes.find { |attr| attr.name == field }
          build_attribute(attribute, attrs) if attribute
        end
      end

      def build_attribute(attribute, attrs)
        attrs[attribute.name] = AttributeBuilder.build(
          resource,
          instance: instance,
          write: write,
          attribute: attribute,
          context: context,
          example_id: example_id
        )
      rescue AttributeBuilder::UnsupportedError
      end

    end
  end
end
