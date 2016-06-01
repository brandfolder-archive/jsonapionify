module JSONAPIonify::Api
  module Resource::Builders
    class AttributesBuilder < FieldsBuilder

      delegate :attributes, to: :resource, prefix: true

      private

      def build_default
        resource_attributes.each_with_object(Objects::Attributes.new) do |attribute, attrs|
          if attribute.supports_read_for_action?(action_name, context) && !attribute.hidden_for_action?(action_name)
            attrs[attribute.name] = attribute.resolve(instance, context, example_id: example_id)
          end
        end
      end

      def build_sparce
        resource_fields.each_with_object(Objects::Attributes.new) do |field, attrs|
          field = field.to_sym
          attribute = resource_attributes.find { |attr| attr.name == field }
          if attribute&.supports_read_for_action?(action_name, context)
            attrs[field] = attribute.resolve(instance, context, example_id: example_id)
          end
        end
      end

    end
  end
end
