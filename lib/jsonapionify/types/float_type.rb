module JSONAPIonify::Types
  class FloatType < BaseType

    def sample(*)
      rand(0.0..201.42).round(2)
    end

    loader do |value|
      raise LoadError, 'input value was not a float' unless value.is_a?(Float)
      value
    end

    dumper do |value|
      raise DumpError, 'cannot convert value to float' unless value.respond_to?(:to_f)
      value.to_f.tap do |float|
        raise DumpError, 'output value was not a float' unless float.is_a? Float
      end
    end

  end
end
