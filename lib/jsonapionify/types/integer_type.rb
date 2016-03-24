module JSONAPIonify::Types
  class IntegerType < BaseType

    def sample(*)
      rand(1..123)
    end

    def load(value)
      raise LoadError, 'input value was not an Integer' unless value.is_a?(Fixnum)
      value
    end

    def dump(value)
      raise DumpError, 'cannot convert value to Integer' unless value.respond_to?(:to_i)
      value.to_i.tap do |int|
        raise DumpError, 'output value was not a Float' unless int.is_a? Integer
      end
    end

  end
end
