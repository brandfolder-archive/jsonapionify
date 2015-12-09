module JSONAPIonify
  module InheritedAttributes

    def inherited_hash_attribute(*attrs)
      attrs.each do |attr|
        ivar   = :"@#{attr}"
        setter = :"#{attr}="
        getter = :"#{attr}"

        # Define First Variable
        instance_variable_set(ivar, Hash.new)

        # Define Setter
        define_singleton_method setter do |value|
          instance_variable_get(ivar).replace(value)
        end

        # Define Getter
        define_singleton_method getter do
          instance_variable_get(ivar)
        end

        # Define Inheritor
        existing_inheritor = method(:inherited)
        define_singleton_method :inherited do |subclass|
          # Call previous inheritor
          existing_inheritor.call(subclass)

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
    end

    def inherited_array_attribute(*attrs)
      attrs.each do |attr|
        ivar   = :"@#{attr}"
        setter = :"#{attr}="
        getter = :"#{attr}"

        # Define First Variable
        instance_variable_set(ivar, Array.new)

        # Define Setter
        define_singleton_method setter do |value|
          instance_variable_get(ivar).replace(value)
        end

        # Define Getter
        define_singleton_method getter do
          instance_variable_get(ivar)
        end

        # Define Inheritor
        existing_inheritor = method(:inherited)
        define_singleton_method :inherited do |subclass|
          # Call previous inheritor
          existing_inheritor.call(subclass)

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
    end

  end
end
