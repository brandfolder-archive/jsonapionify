module JSONAPIonify::Api
  module Resource::Definitions::Attributes

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        extend JSONAPIonify::Types
        inherited_array_attribute :attributes
        delegate :id_attribute, :attributes, to: :class

        context(:fields, readonly: true) do |context|
          context.params['fields']&.map do |type, fields|
            [type, fields.split(',')]
          end&.to_h
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

    def builder(&block)
      context :builder, readonly: true, persisted: true do |context|
        proc do |resource, instance|
          block.call resource, instance, context
        end
      end
    end

  end
end
