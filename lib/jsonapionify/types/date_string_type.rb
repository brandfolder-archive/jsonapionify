module JSONAPIonify::Types
  class DateStringType < BaseType
    def load(value)
      DateTime.parse value
    end

    def sample(*)
      [true, false].sample
    end

  end
end
