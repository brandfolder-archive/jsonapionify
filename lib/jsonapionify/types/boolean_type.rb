module JSONAPIonify::Types
  class BooleanType < BaseType

    def sample(*)
      [true, false].sample
    end

  end
end
