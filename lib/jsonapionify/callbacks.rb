module JSONAPIonify
  module Callbacks
    extend ActiveSupport::Concern
    included do

      def self.define_callbacks(*names)
        names.each do |name|
          chain_name = "__#{name}_callback_chain"
          define_method chain_name do |*args, &block|
            instance_exec(*args, &block)
          end

          define_singleton_method "before_#{name}" do |sym = nil, &outer_block|
            outer_block = (outer_block || sym).to_proc
            prev_chain  = instance_method(chain_name)
            define_method chain_name do |*args, &block|
              instance_exec(*args, &outer_block) != false &&
                prev_chain.bind(self).call(&block)
            end
          end

          define_singleton_method "after_#{name}" do |sym = nil, &outer_block|
            outer_block = (outer_block || sym).to_proc
            prev_chain  = instance_method(chain_name)
            define_method chain_name do |*args, &block|
              prev_chain.bind(self).call(&block)
              instance_exec(*args, &outer_block)
            end
          end

        end
      end
    end

    def run_callbacks(name, *args, &block)
      block ||= proc {}
      send("__#{name}_callback_chain", *args, &block)
    end

  end
end
