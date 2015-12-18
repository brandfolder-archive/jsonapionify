require 'faker'

module JSONAPIonify::Types
  class DateStringType < BaseType
    def load(value)
      Date.parse value
    end

    def dump(value)
      case value
      when Date
        JSON.load JSON.dump(value.to_date)
      else
        raise TypeError, "#{value} is not a valid JSON #{name}."
      end
    end

    def sample(field_name)
      field_name = field_name.to_s
      if field_name.to_s.end_with?('ed_at') || field_name.include?('start')
        Faker::Date.backward
      elsif field_name.include?('end')
        Faker::Date.forward
      end
    end

  end
end
