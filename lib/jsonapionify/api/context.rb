module JSONAPIonify::Api
  class Context

    attr_reader :definitions

    def initialize(request, definitions)
      @request     = request
      @definitions = definitions.dup
      @memo        = {}
    end

    def [](k)
      @memo[k] ||= @definitions[k].call(@request, self)
    end

    def []=(k, v)
      @memo[k] = v
    end

  end
end