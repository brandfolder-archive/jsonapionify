require 'faker'

module JSONAPIonify::Types
  class StringType < BaseType
    class StringSampler
      delegate *Faker::Address.methods(false), to: Faker::Address
      delegate *Faker::Code.methods(false), to: Faker::Code
      delegate :suffix, :catch_phrase, :bs, :ein, :duns_number, :logo, to: Faker::Company
      alias_method :slogan, :catch_phrase
      delegate :name, to: Faker::Company, prefix: :company
      alias_method :company, :company_name
      delegate :credit_card, to: Faker::Finance, prefix: :company
      delegate *Faker::Internet.methods(false), to: Faker::Internet
      delegate :first_name, :last_name, :prefix, :suffix, :title, to: Faker::Name
      delegate *Faker::PhoneNumber.methods(false), to: Faker::PhoneNumber
      alias_method :phone, :phone_number
      alias_method :mobile, :cell_phone
      alias_method :cell, :cell_phone
      delegate *Faker::Commerce.methods(false), to: Faker::Commerce
      delegate *Faker::Avatar.methods(false), to: Faker::Avatar, prefix: :avatar
      alias_method :avatar_url, :avatar_image
      alias_method :profile_image, :avatar_image
      alias_method :profile_pic, :avatar_image
      delegate :birthday, to: Faker::Date

      def initialize(field_name)
        @field_name = field_name
      end

      def hacker_speak
        Faker::Hacker.say_something_smart
      end

      def full_name
        Faker::Name.name
      end

      def domain
        [Faker::Internet.domain_word, Faker::Internet.domain_suffix].join '.'
      end

      def description
        Faker::Lorem.paragraph
      end

      alias_method :body, :description
      alias_method :content, :description
      alias_method :prompt, :description

      def value
        if self.class.instance_methods(false).include?(@field_name)
          public_send(@field_name)
        elsif (field = self.class.instance_methods(false).find { |m| @field_name.to_s.include? m.to_s })
          public_send(field)
        else
          Faker::Lorem.word
        end
      end

    end

    def load(value)
      raise LoadError, 'input value was not a String' unless value.is_a?(String)
      value
    end

    def dump(value)
      raise DumpError, 'cannot convert value to String' unless value.respond_to?(:to_s)
      value.to_s.tap do |string|
        raise DumpError, 'output value was not a String' unless string.is_a? String
      end
    end

    def sample(field_name)
      StringSampler.new(field_name).value
    end
  end
end
