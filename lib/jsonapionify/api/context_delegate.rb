module JSONAPIonify::Api
  class ContextDelegate
    class Mock
      def initialize(**attrs)
        attrs.each do |attr, value|
          define_singleton_method(attr){ value }
        end
      end

      def method_missing(*)
        self
      end
    end

    def initialize(request, instance, definitions, **overrides)
      memo          = {}
      persisted_memo = {}
      delegate      = self
      @definitions  = definitions

      define_singleton_method :request do
        request
      end

      %i{initialize_dup initialize_clone}.each do |method|
        define_singleton_method method do |copy|
          memo.each do |k, v|
            copy.public_send "#{k}=", v
          end
        end
      end

      define_singleton_method(:reset) do |key|
        memo.delete(key)
      end

      define_singleton_method(:clear) do
        memo.clear
      end

      definitions.each do |name, context|
        define_singleton_method name do
          return persisted_memo[name] if persisted_memo.has_key? name
          (context.persisted? ? persisted_memo : memo)[name] ||=
            if overrides.has_key?(name)
              overrides[name]
            else
              context.call(instance, delegate)
            end
        end

        define_singleton_method "#{name}=" do |value|
          persisted_memo[name] = value
        end unless context.readonly?
      end
    end

  end
end
