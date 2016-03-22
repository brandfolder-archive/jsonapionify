module JSONAPIonify::Api
  module Resource::Definitions::Attributes

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        extend JSONAPIonify::Types
        inherited_array_attribute :attributes
        delegate :id_attribute, :attributes, to: :class

        context(:fields, readonly: true) do |context|
          should_error = false
          fields       = (context.request.params['fields'] || {}).each_with_object(self.class.api.fields) do |(type, fields), field_map|
            type_sym            = type.to_sym
            field_map[type_sym] =
              fields.to_s.split(',').map(&:to_sym).each_with_object([]) do |field, field_list|
                attribute = self.class.api.resource(type_sym).attributes.find do |attribute|
                  attribute.read? && attribute.name == field
                end
                attribute ? field_list << attribute.name : error(:field_not_permitted, type, field) && (should_error = true)
              end
          end
          raise Errors::RequestError if should_error
          fields
        end
      end
    end

    def id(sym)
      define_singleton_method :id_attribute do
        sym
      end
    end

    def attribute(name, type, description = '', **options, &block)
      Attribute.new(name, type, description, **options, &block).tap do |new_attribute|
        attributes.delete(new_attribute)
        attributes << new_attribute
      end
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

  end
end
