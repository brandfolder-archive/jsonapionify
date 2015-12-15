module JSONAPIonify::Types
  class ArrayType < BaseType

    after_initialize do
      unless options[:of].is_a? BaseType
        raise TypeError, "#{options[:of]} is not a valid JSON type."
      end
    end

    def load(value)
      super unless options[:of]
      value.map do |item|
        options[:of].load(item)
      end
    end

    def dump(value)
      super unless options[:of]
      value.map do |item|
        options[:of].dump(item)
      end
    end

    def sample(field_name)
      3.times.map do
        (options[:of] || StringType.new).sample(field_name)
      end
    end

  end
end
