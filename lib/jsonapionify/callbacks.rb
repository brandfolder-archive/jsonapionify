module JSONAPIonify
  module Callbacks
    extend ActiveSupport::Concern
    included do

      def self.define_callbacks(*names)
        names.each do |name|
          chain_name = "__#{name}_callback_chain"
          define_method chain_name do |&block|
            instance_eval(&block)
          end

          define_singleton_method "before_#{name}" do |sym = nil, &outer_block|
            outer_block = (outer_block || sym).to_proc
            prev_chain  = instance_method(chain_name)
            define_method chain_name do |&block|
              instance_eval(&outer_block) != false &&
                prev_chain.bind(self).call(&block)
            end
          end

          define_singleton_method "after_#{name}" do |sym = nil, &outer_block|
            outer_block = (outer_block || sym).to_proc
            prev_chain  = instance_method(chain_name)
            define_method chain_name do |&block|
              prev_chain.bind(self).call(&block)
              instance_eval(&outer_block)
            end
          end

        end
      end
    end

    def run_callbacks(name, &block)
      send("__#{name}_callback_chain", &block)
    end

  end
end
