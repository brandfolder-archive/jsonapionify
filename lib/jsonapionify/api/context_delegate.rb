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
      memo         = {}
      delegate     = self
      @definitions = definitions

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

      definitions.each do |name, context|
        define_singleton_method name do
          memo[name] ||=
            overrides.has_key?(name) ?
              overrides[name] : context.call(instance, delegate)
        end

        define_singleton_method "#{name}=" do |value|
          memo[name] = value
        end unless context.readonly?
      end
    end

  end
end
