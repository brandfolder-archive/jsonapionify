require 'active_support/core_ext/module/delegation'

module JSONAPIonify::Structure
  module Helpers
    class Errors
      include Enumerable

      delegate :clear, :present?, :blank?, :each, to: :@hash

      def initialize
        @hash = {}
      end

      def initialize_copy(new_copy)
        super
        instance_variables.each do |ivar|
          new_copy.instance_variable_set(
            ivar, instance_variable_get(ivar).dup
          ) rescue nil
        end
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

      def as_collection
        each_with_object(Collections::Errors.new) do |(pointer, messages), collection|
          *, key = pointer.to_s.split('/')
          entity = key.present? ? key : 'object'
          messages.each do |message|
            message = "#{entity} #{message}".chomp('.') << '.'
            object  = {
              source: {
                pointer: pointer
              },
              detail: message,
              status: "422"
            }
            collection << object
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
