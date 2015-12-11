module JSONAPIonify::Api
  class ContextDelegate

    attr_reader :definitions

    def initialize(request, instance, definitions)
      memo     = {}
      delegate = self

      define_singleton_method :request do
        request
      end

      definitions.each do |name, context|
        define_singleton_method name do
          memo[name] ||= context.call(instance, delegate)
        end

        define_singleton_method "#{name}=" do |value|
          memo[name] = value
        end unless context.readonly?
      end
    end

  end
end