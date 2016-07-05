module JSONAPIonify::DestructuredProc
  refine Proc do
    def destructure(at_index = arguments.length-1)
      return self unless kwargs.present?
      original = self
      Proc.new do |*args|
        kwargs = original.kwargs_destructured(args[at_index])
        instance_exec(*args, **kwargs, &original)
      end
    end

    def kwargs
      parameters.select { |t, k| t.to_s.start_with? 'key' }
    end

    def arguments
      parameters.reject { |t, k| t.to_s.start_with? 'key' }
    end

    def kwargs_destructured(target)
      kwargs.each_with_object({}) do |(_, key), kw|
        next unless target.respond_to? key
        kw[key] = target.public_send(key)
      end
    end
  end
end
