require 'active_support/core_ext/module/delegation'

module JSONAPIObjects
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

    def all_messages
      @hash.map do |key, error|
        [backtick_key(key), error].join(' ')
      end
    end

    def backtick_key(key)
      "`#{key}`"
    end

  end
end
