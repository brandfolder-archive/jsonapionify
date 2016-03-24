require 'faker'

module JSONAPIonify::Types
  class TimeStringType < StringType
    def load(value)
      Time.parse super(value)
    end

    def dump(value)
      raise DumpError, 'cannot convert value to Time' unless value.respond_to?(:to_time)
      JSON.load JSON.dump(value.to_time)
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
