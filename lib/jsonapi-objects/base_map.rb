module JSONAPIObjects
  class BaseMap < BaseObject

    def self.value_is(type_class, strict: false)
      define_method(:type_class) do
        type_class
      end
      type! must_be: type_class if strict
    end

    def self.type!(**opts)
      type_of! '*', **opts
    end

    def coerce_value(_, v)
      return v unless v.is_a? Hash
      type_class.new v
    end

  end
end
