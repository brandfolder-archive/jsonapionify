require 'active_support/core_ext/hash/keys'

module JSONAPIonify::Types
  class ObjectType < BaseType

    def load(value)
      super(value).deep_symbolize_keys
    end

    def dump(value)
      super(value.deep_stringify_keys)
    end

  end
end
