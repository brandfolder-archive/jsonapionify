module JSONAPIonify::Api
  module Resource::AttributeDefinitions

    class Attribute
      attr_reader :name, :type, :description, :read, :write, :required

      def initialize(name, type, description, read: true, write: true, required: false)
        @name        = name
        @type        = type
        @description = description
        @read        = read
        @write       = write
        @required    = required
      end

      def required?
        !!@required
      end

      def read?
        !!@read
      end

      def write?
        !!@write
      end

      def allow
        Array.new.tap do |ary|
          ary << 'read' if read?
          ary << 'write' if write?
        end
      end
    end

    def self.extended(klass)
      klass.class_eval do
        delegate :attributes, to: :class
      end
    end

    def inherited(subclass)
      super
      observe(attributes).added do
        subclass.attributes.merge! attributes
      end.removed do |items|
        subclass.attributes.delete_if do |k, v|
          items[k] == v
        end
      end
    end

    def attributes
      @attributes ||= []
    end

    def id(sym)
      define_singleton_method :id_attribute do
        sym
      end
    end

    def attribute(name, *args, **options)
      attributes.delete_if { |attribute| }
      attributes << Attribute.new(name, *args, **options)
    end

  end
end