require 'faker'

module JSONAPIonify::Types
  class TimeStringType < BaseType
    def load(value)
      Time.parse value
    end

    def dump(value)
      case value
      when Time
        JSON.load JSON.dump(value.to_time)
      else
        raise TypeError, "#{value} is not a valid JSON #{name}."
      end
    end

    def sample(field_name)
      field_name = field_name.to_s
      if field_name.to_s.end_with?('ed_at') || field_name.include?('start')
        Faker::Time.backward
      elsif field_name.include?('end')
        Faker::Time.forward
      end
    end

  end
end
