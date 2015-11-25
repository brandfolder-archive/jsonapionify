module JSONAPIObjects
  class Continuation
    using UnstrictProc

    def initialize(**options)
      @options = options
    end

    def check(*arguments)
      yield if check_if(*arguments) && check_unless(*arguments)
    end

    private

    def check_if(*arguments)
      return true unless @options[:if]
      not @options[:if].unstrict.call(*arguments)
    end

    def check_unless(*arguments)
      return true unless @options[:unless]
      not @options[:unless].unstrict.call(*arguments)
    end

  end
end
