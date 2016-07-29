module JSONAPIonify::Api
  module Resource::Documentation

    def self.extended(mod)
      mod.example_id_generator { |val| val }
    end

    def documented_actions_in_order
      indexes = %i{list create read update delete add replace remove}
      documented_actions.reject do |a, *|
        ['HEAD', 'OPTIONS'].include? a.request_method
      end.sort_by do |action, *|
        indexes.index(action.name) || indexes.length
      end
    end

    def documentation_object(base_url)
      OpenStruct.new(
        name:          type,
        description:   JSONAPIonify::Documentation.render_markdown(@description || ''),
        relationships: relationships.map { |r| r.documentation_object },
        attributes:    attributes.sort_by(&:name).map(&:documentation_object),
        actions:       documented_actions_in_order.map do |action, base, args|
          action.documentation_object File.join(base_url, base), *args
        end
      )
    end

    def example_id_generator(&block)
      index = 0
      define_singleton_method(:generate_id) do
        instance_exec index += 1, &block
      end
      context :example_id do
        self.class.generate_id
      end
    end

    def example_instance_for_action(action, context, write = false)
      id = generate_id
      OpenStruct.new.tap do |instance|
        instance.send "#{id_attribute}=", id.to_s
        actionable_attributes = attributes.select do |attr|
          if write
            attr.supports_write_for_action?(action, context)
          else
            attr.supports_read_for_action?(action, context)
          end
        end
        actionable_attributes.each do |attribute|
          instance.send "#{attribute.name}=", attribute.example(id)
        end

        instance.define_singleton_method :method_missing do |*args|
          self
        end
      end
    end

  end
end
