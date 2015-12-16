module JSONAPIonify::Types
  class BooleanType < BaseType

    def load(value)

    end
    
    def dump(value)
      case value
      when true, false
        value
      else
        raise TypeError, "#{value} is not a valid JSON #{name}."
      end
    end

    def sample(*)
      [true, false].sample
    end

  end
end
