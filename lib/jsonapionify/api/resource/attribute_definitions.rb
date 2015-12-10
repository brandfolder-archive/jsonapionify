module JSONAPIonify::Api
  module Resource::AttributeDefinitions

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_array_attribute :attributes
        delegate :attributes, to: :class
      end
    end

    def id(sym)
      define_singleton_method :id_attribute do
        sym
      end
    end

    def attribute(name, *args, **options)
      Attribute.new(name, *args, **options).tap do |new_attribute|
        attributes.delete(new_attribute)
        attributes << new_attribute
      end
    end

  end
end
