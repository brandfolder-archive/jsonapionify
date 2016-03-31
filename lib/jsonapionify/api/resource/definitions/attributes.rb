module JSONAPIonify::Api
  module Resource::Definitions::Attributes

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        extend JSONAPIonify::Types
        inherited_array_attribute :attributes
        delegate :id_attribute, :attributes, to: :class

        context(:fields, readonly: true) do |context|
          should_error      = false
          input_fields      = context.request.params['fields'] || {}
          actionable_fields = self.class.fields_for_action(context.action_name)
          input_fields.each_with_object(
            actionable_fields
          ) do |(type, fields), field_map|
            type_sym            = type.to_sym
            field_symbols       = fields.to_s.split(',').map(&:to_sym)
            field_map[type_sym] =
              field_symbols.each_with_object([]) do |field, field_list|
                type_attributes = self.class.api.resource(type_sym).attributes
                attribute = type_attributes.find do |attribute|
                  attribute.name == field &&
                    attribute.read? &&
                    attribute.supports_action?(context.action_name)
                end
                if attribute
                  field_list << attribute.name
                else
                  error(:field_not_permitted, type, field)
                  should_error = true
                end
              end
          end.tap do
            raise Errors::RequestError if should_error
          end
        end
      end
    end

    def id(sym)
      define_singleton_method :id_attribute do
        sym
      end
    end

    def attribute(name, type, description = '', **options, &block)
      Attribute.new(
        name, type, description, **options, &block
      ).tap do |new_attribute|
        attributes.delete(new_attribute)
        attributes << new_attribute
      end
    end

    def remove_attribute(name)
      attributes.delete_if { |attr| attr.name == name.to_sym }
    end

    def fields
      attributes.select(&:read?).map(&:name)
    end

    def builder(&block)
      context :builder, readonly: true do |context|
        proc do |resource, instance|
          block.call resource, instance, context
        end
      end
    end

    def field_valid?(name)
      fields.include? name.to_sym
    end

    def fields_for_action(action)
      api.fields.each_with_object({}) do |(type, attrs), fields|
        fields[type] = attrs.select do |attr|
          api.resource(type).attributes.find do |type_attr|
            type_attr.name == attr
          end.supports_action? action
        end
      end
    end

  end
end
