require 'faker'

module JSONAPIonify::Types
  class TimeStringType < StringType
    loader do |value|
      Time.parse super(value)
    end

    dumper do |value|
      raise DumpError, 'cannot convert value to time' unless value.respond_to?(:to_time)
      JSON.load JSON.dump(value.to_time)
    end

    def sample(field_name)
      field_name = field_name.to_s
      if field_name.to_s.end_with?('ed_at') || field_name.include?('start')
        Faker::Time.backward
      elsif field_name.include?('end')
        Faker::Time.forward
      else
        Faker::Time.backward
      end
    end

  end
end
