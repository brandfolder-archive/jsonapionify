module JSONAPIonify::Types
  class FloatType < BaseType

    def sample(*)
      rand(0.0..201.42).round(2)
    end
  end
end
