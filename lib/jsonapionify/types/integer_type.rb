module JSONAPIonify::Types
  class IntegerType < BaseType

    def sample(*)
      rand(1..123)
    end

  end
end
