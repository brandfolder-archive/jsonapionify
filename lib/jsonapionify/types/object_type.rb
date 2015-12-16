require 'active_support/core_ext/hash/keys'

module JSONAPIonify::Types
  class ObjectType < BaseType

    def load(value)
      super(value).deep_symbolize_keys
    end

    def dump(value)
      super(value.deep_stringify_keys)
    end

    def sample(field_name)
      field_name = field_name.to_s.singularize.to_sym
      %i{foo bar baz}.each_with_object({}) do |k, h|
        h[k] = StringType.new.sample(field_name)
      end
    end

  end
end
