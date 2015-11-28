module JSONAPIObjects
  class BaseCollection < Array
    include EnumerableObserver
    include InheritsOrigin
    attr_reader :parent

    def self.value_is(type_class)
      define_method(:type_class) do
        type_class
      end
    end

    def initialize(array = [])
      observe(added: ->(_, items) {
        items.each do |item|
          item.instance_variable_set(:@parent, self) unless item.frozen?
        end
      })
      array.each do |instance|
        self << instance
      end
    end

    def original_method(method)
      Array.instance_method(method).bind(self)
    end

    def new(**attributes)
      self << attributes
    end

    def <<(instance)
      new_instance =
        case instance
        when Hash
          type_class.new **instance
        when type_class
          instance
        else
          raise ValidationError,
                "Can't initialize collection `#{self.class.name}` with a type of `#{instance.class.name}`"
        end
      super new_instance
    end

    alias_method :append, :new

    value_is BaseObject

    private

    def items_added(items)
      items.each do |item|
        item.instance_variable_set(:@parent, self)
      end
    end
  end
end
