module JSONAPIonify
  module InheritedAttributes

    def inherited_hash_attribute(*attrs, instance_reader: true, instance_writer: true, instance_accessor: true)
      instance_reader, instance_writer = false, false unless instance_accessor
      attrs.each do |attr|
        ivar   = :"@#{attr}"
        setter = :"#{attr}="
        getter = :"#{attr}"

        # Define First Variable
        instance_variable_set(ivar, Hash.new)

        # Define Setter
        define_singleton_method setter do |value|
          instance_variable_get(ivar).tap(&:clear).merge! value
        end

        # Define Getter
        define_singleton_method getter do
          instance_variable_get(ivar)
        end

        # Define Instance Getter
        define_method getter do
          if instance_variable_defined?(ivar)
            instance_variable_get(ivar)
          else
            instance_variable_set(
              ivar,
              self.class.instance_variable_get(ivar).dup
            )
          end
        end if instance_reader

        # Define Instance Setter
        define_method setter do |value|
          instance_variable_get(ivar).tap(&:clear).merge! value
        end if instance_writer

        # Define Inheritor
        mod = Module.new do
          define_method :inherited do |subclass|
            super(subclass)

            # Set subclass variable
            subclass.instance_variable_set(ivar, Hash.new)
            parent_var   = instance_variable_get(ivar)
            subclass_var = subclass.instance_variable_get(ivar)

            # Merge changes from parent
            subclass_var.deep_merge!(parent_var)

            # Observe
            observer = EnumerableObserver.observe(parent_var)
            observer.added { |items| subclass_var.deep_merge! items.to_h }
            observer.removed { |items| subclass_var.delete_if { |k, v| items.to_h[k] == v } }
          end
        end
        extend mod
      end
    end

    def inherited_array_attribute(*attrs, instance_reader: true, instance_writer: true, instance_accessor: true)
      attrs.each do |attr|
        ivar   = :"@#{attr}"
        setter = :"#{attr}="
        getter = :"#{attr}"

        # Define First Variable
        instance_variable_set(ivar, Array.new)

        # Define Setter
        define_singleton_method setter do |value|
          instance_variable_get(ivar).tap(&:clear).concat(value)
        end

        # Define Getter
        define_singleton_method getter do
          instance_variable_get(ivar)
        end

        # Define Instance Getter
        define_method getter do
          if instance_variable_defined?(ivar)
            instance_variable_get(ivar)
          else
            instance_variable_set(
              ivar,
              self.class.instance_variable_get(ivar).dup
            )
          end
        end if instance_reader

        # Define Instance Setter
        define_method setter do |value|
          instance_variable_get(ivar).tap(&:clear).concat(value)
        end if instance_writer

        # Define Inheritor
        mod = Module.new do
          define_method :inherited do |subclass|
            super(subclass)

            # Set subclass variable
            subclass.instance_variable_set(ivar, Array.new)
            parent_var   = instance_variable_get(ivar)
            subclass_var = subclass.instance_variable_get(ivar)

            # Merge changes from parent
            subclass_var.concat(parent_var)

            # Observe
            observer = EnumerableObserver.observe(parent_var)
            observer.added { |items| subclass_var.concat items }
            observer.removed { |items| items.each { |item| subclass_var.delete item } }
          end
        end
        extend mod
      end
    end

  end
end
