module JSONAPIonify::Api
  ResourceNotDefined = Class.new StandardError

  module Base::ResourceDefinitions

    def defined_resources
      @defined_resources ||= {}
    end

    def resource(type)
      raise ArgumentError, 'type required' if type.nil?
      type       = type.to_sym
      const_name = type.to_s.camelcase
      return const_get(const_name, false) if const_defined?(const_name, false)
      raise ResourceNotDefined, "Resource not defined: #{type}" unless resource_defined?(type)
      const_set const_name, Class.new(resource_class, &defined_resources[type]).set_type(type)
    end

    def resource_defined?(name)
      !!defined_resources[name]
    end

    def resources
      defined_resources.each_with_object({}) do |(name, _), hash|
        hash[name] = resource(name)
      end
    end

    def define_resource(name, &block)
      const_name = name.to_s.camelcase
      remove_const(const_name) if const_defined? const_name
      defined_resources[name.to_sym] = block
    end

  end
end
