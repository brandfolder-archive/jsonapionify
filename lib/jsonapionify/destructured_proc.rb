module JSONAPIonify::DestructuredProc
  refine Proc do
    def destructure(at_index = arguments.length-1)
      original = self
      Proc.new do |*args|
        kwargs = original.kwargs(args[at_index])
        begin
          instance_exec(*args, **kwargs, &original)
        end
      end
    end

    def arguments
      parameters.reject { |t, k| t.to_s.start_with? 'key' }
    end

    def kwargs(target)
      parameters.each_with_object({}) do |(type, key), kw|
        next unless type == :key || type == :keyreq
        next unless target.respond_to? key
        kw[key] = target.public_send(key)
      end
    end
  end
end
