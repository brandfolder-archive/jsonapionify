module JSONAPIObjects
  module MemberNames
    extend self

    def valid?(value)
      return false if value.nil?
      value = value.to_s if value.is_a? Symbol
      [
        value.present?,
        valid_ends?(value),
        contains_valid_characters?(value),
        !contains_invalid_characters?(value)
      ].reduce(:&)
    end

    private

    def contains_valid_characters?(value)
      value =~ /\A[a-zA-Z0-9\u0080-\uFFFF_\s-]+\Z/
    end

    def valid_ends?(value)
      ['-', '_', ' '].map do |char|
        !value.start_with?(char) & !value.end_with?(char)
      end.reduce(:&)
    end

    def contains_invalid_characters?(value)
      %w{+ , . [ ] ! " # $ % & ' ( ) * / : ; < = > ? @ \\ ^ ` { } | ~}.map do |char|
        value.include? char
      end.reduce(:|)
    end

  end
end
