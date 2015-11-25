module JSONAPIObjects
  class Continuation

    def initialize(**options)
      @options = options
    end

    def check(*arguments)
      yield if check_if(*arguments) && check_unless(*arguments)
    end

    private

    def check_if(*arguments)
      return true unless @options[:if]
      procerize(@options[:if]).call(*arguments)
    end

    def check_unless(*arguments)
      return true unless @options[:unless]
      not procerize(@options[:unless]).call(*arguments)
    end

    private

    def procerize(lam)
      Proc.new do |*arguments|
        req_arg_count = lam.parameters.select { |type, _| type == :req }.count
        if req_arg_count > arguments.count
          (req_arg_count - arguments.count).times { arguments << nil }
        elsif req_arg_count < arguments.count
          arguments = arguments[0..(req_arg_count - 1)]
        end
        lam.call(*arguments)
      end
    end

  end
end
