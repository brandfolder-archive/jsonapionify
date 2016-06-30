module JSONAPIonify::Api
  class ContextDelegate
    class Mock
      def initialize(**attrs)
        attrs.each do |attr, value|
          define_singleton_method(attr) { value }
        end
      end

      def method_missing(*)
        self
      end
    end

    attr_reader :request

    def initialize(request, resource_instance, definitions, **overrides)
      @memo              = {}
      @request           = request
      @persisted_memo    = {}
      @definitions       = definitions
      @overrides         = overrides
      @resource_instance = resource_instance
      delegate           = self

      %i{initialize_dup initialize_clone}.each do |method|
        define_singleton_method method do |copy|
          @memo.each do |k, v|
            copy.public_send "#{k}=", v
          end
        end
      end

      definitions.each do |name, context|
        raise Errors::ReservedContextName if respond_to? name
        define_singleton_method name do
          return @overrides[name] if @overrides.has_key? name
          return @persisted_memo[name] if @persisted_memo.has_key? name
          return @memo[name] if @memo.has_key? name
          write_memo = (context.persisted? ? @persisted_memo : @memo)
          write_memo[name] = context.call(@resource_instance, delegate)
        end

        define_singleton_method "#{name}=" do |value|
          @persisted_memo[name] = value
        end unless context.readonly?
      end
      freeze
    end

    def kwargs(block)
      keys = block&.parameters&.select { |type, _| type == :key || type == :keyreq } || []
      keys.each_with_object({}) do |(type, key), kw|
        kw[key] = send(key) if type == :keyreq || __has_context?(key)
      end
    end

    def reset key
      @memo.delete(key)
    end

    def clear
      @memo.clear
    end

    def inspect
      to_s.chomp('>') << " memoed: #{@memo.keys.inspect}, persisted: #{@persisted_memo.keys.inspect}, overridden: #{@overrides.keys}" << '>'
    end

    private

    def __has_context?(name)
      [@definitions, @overrides, @memo, @persisted_memo].map(&:keys).reduce(:|).include? name
    end

  end
end
