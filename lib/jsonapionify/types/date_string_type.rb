require 'faker'

module JSONAPIonify::Types
  class DateStringType < StringType
    def load(value)
      Date.parse super(value)
    end

    def dump(value)
      raise DumpError, 'cannot convert value to Date' unless value.respond_to?(:to_date)
      JSON.load JSON.dump(value.to_date)
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

