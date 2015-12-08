module JSONAPIonify
  module InheritedHashAttributes

    def inherited_hash_attribute(*attrs)
      attrs.each do |attr|
        # Define Setter
        define_singleton_method "#{attr}=" do
          instance_variable_get("@#{attr}")
        end

        # Define Getter
        define_singleton_method "#{attr}" do
          if instance_variable_defined?("@#{attr}")
            instance_variable_get("@#{attr}")
          else
            instance_variable_set("@#{attr}", Hash.new)
          end
        end

        # Define Inheritor
        define_singleton_method :inherited do |subclass|
          super(subclass)
          subclass.send(attr).merge! send(attr)
          observe(send(attr)).added do |items|
            subclass.send(attr).merge! items.to_h
          end.removed do |items|
            subclass.send(attr).delete_if do |k, v|
              items.to_h[k] = v
            end
          end
        end
      end
    end

  end
end