module JSONAPIonify::Api
  class Context

    def initialize(request, definitions)
      definitions.each do |name, block|
        define_singleton_method name do
          if instance_variable_defined?("@#{name}")
            instance_variable_get("@#{name}")
          else
            instance_variable_set("@#{name}", block.call(request, self))
          end
        end
      end
    end

    def method_missing(m, *args)
      if m.to_s.end_with?('=')
        attribute = m.to_s.chomp('=')
        value = args.first
        define_singleton_method attribute do
          value
        end
      end
    end

  end
end