require 'active_support/core_ext/module/delegation'

module JSONAPIonify::Structure
  module Helpers
    class Errors
      include Enumerable

      delegate :present?, :blank?, :each, to: :@hash

      def initialize
        @hash = {}
      end

      def add(key, value)
        (@hash[key] ||= []) << value
      end

      alias_method :[]=, :add

      def [](key)
        @hash[key]
      end

      def replace(key, messages)
        @hash[key] = Array.wrap(messages)
      end

      def all_messages
        @hash.each_with_object([]) do |(key, errors), messages|
          errors.each do |error|
            messages << [backtick_key(key), error].join(' ')
          end
        end
      end

      private

      def backtick_key(key)
        "`#{key}`"
      end

    end
  end
end
