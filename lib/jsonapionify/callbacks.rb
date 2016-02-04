require 'active_support/concern'

module JSONAPIonify
  module Callbacks
    extend ActiveSupport::Concern
    included do

      def self.define_callbacks(*names)
        names.each do |name|
          chains = {
            main:   "__#{name}_callback_chain",
            before: "__#{name}_before_callback_chain",
            after:  "__#{name}_after_callback_chain"
          }
          define_method chains[:main] do |*args, &block|
            block ||= proc {}
            if send(chains[:before], *args) != false
              value = instance_exec(*args, &block)
              value if send(chains[:after], *args) != false
            end
          end unless method_defined? chains[:main]

          # Define before and after chains
          %i{after before}.each do |timing|
            define_method chains[timing] { |*| } unless method_defined? chains[timing]

            define_singleton_method "#{timing}_#{name}" do |sym = nil, &outer_block|
              outer_block = (outer_block || sym).to_proc
              prev_chain  = instance_method(chains[timing])
              define_method chains[timing] do |*args, &block|
                if prev_chain.bind(self).call(*args, &block) != false
                  instance_exec(*args, &outer_block)
                end
              end
            end
          end

          private *chains.values

        end
      end
    end

    def run_callbacks(name, *args, &block)
      send("__#{name}_callback_chain", *args, &block)
    end

  end
end
