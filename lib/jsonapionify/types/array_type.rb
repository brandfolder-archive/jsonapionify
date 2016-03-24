module JSONAPIonify::Types
  class ArrayType < BaseType

    after_initialize do
      unless options[:of].is_a? BaseType
        raise TypeError, "#{options[:of]} is not a valid JSON type."
      end
    end

    def sample(field_name)
      field_name = field_name.to_s.singularize.to_sym
      3.times.map do
        (options[:of] || StringType.new).sample(field_name)
      end
    end

    def load(value)
      raise LoadError, 'invalid type' unless value.is_a?(Array)
      return super(value) unless options[:of]
      value.map do |item|
        options[:of].load(item)
      end
    end

    def dump(value)
      raise DumpError, 'cannot convert value to Array' unless value.respond_to?(:to_a)
      value.to_a.tap do |array|
        raise DumpError, 'output value was not an array' unless array.is_a? Array
      end
      return super(value) unless options[:of]
      value.map do |item|
        options[:of].dump(item)
      end
    end

  end
end
