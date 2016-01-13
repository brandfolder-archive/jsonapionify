module JSONAPIonify::Api
  class MiddlewareStack

    def initialize
      @stack = []
    end

    def initialize_copy(new_instance)
      new_instance.instance_exec(@stack) do |stack|
        @stack = stack
      end
    end

    def install(rack_app)
      @stack.each do |*args|
        rack_app.use *args
      end
    end

    def unshift(name, *args)
      @stack.unshift([name, *args])
    end

    def use(name, *args)
      @middlewares << [name, *args]
    end

    def delete(target_name, *target_args)
      return @stack.delete([target_name, *target_args]) if target_args.present?
      @stack.delete_if { |n, *| n == target_name }
    end

    def insert_before(target_name, name, *args)
      target = @stack.find { |n, *| n == target_name }
      index  = @stack.index(target)
      @stack.insert index, [name, *args]
    end

    def insert_after(target_name, name, *args)
      target = @stack.find { |n, *| n == target_name }
      index  = @stack.index(target)
      @stack.insert index + 1, [name, *args]
    end

  end
end
