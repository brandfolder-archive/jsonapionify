require 'active_support/concern'
require 'unstrict_proc'

module JSONAPIonify
  module Callbacks
    extend ActiveSupport::Concern

    module ClassMethods
      def define_callback_strategy(&strategy)
        define_method(:__callback_strategy, &strategy)
      end

      def define_callbacks(*names)
        names.each do |name|
          chains = {
            main:   "__#{name}_callback_chain",
            before: "__#{name}_before_callback_chain",
            after:  "__#{name}_after_callback_chain"
          }
          define_method chains[:main] do |*args, **, &block|
            block ||= proc {}
            false != send(chains[:before], *args) &&
              (value = JSONAPIonify::CustomRescue.perform(remove: __FILE__, source: block, formatter: ->(meta) { meta.source_location.join(':') + ":in callback: `run'" }) do
                __callback_strategy(*args, &block) || true
              end) &&
              false != send(chains[:after], *args) &&
              value
          end unless method_defined? chains[:main]

          # Define before and after chains
          %i{after before}.each do |timing|
            define_method chains[timing] { |*| } unless method_defined? chains[timing]
            callback_name = "#{timing}_#{name}"
            define_singleton_method callback_name do |sym = nil, &outer_block|
              outer_block = (outer_block || sym).to_proc
              prev_chain  = instance_method(chains[timing])
              define_method chains[timing] do |*args, &block|
                false != prev_chain.bind(self).call(*args, &block) &&
                  JSONAPIonify::CustomRescue.perform(remove: __FILE__, source: outer_block, formatter: ->(meta) { meta.source_location.join(':') + ":in callback: `#{timing}_#{name}'" }) do
                    __callback_strategy(*args, &outer_block)
                  end
              end
            end
          end

          private(*chains.values)

        end
      end
    end

    included do
      define_callback_strategy do |*args, &block|
        instance_exec(*args, &block)
      end
    end

    def run_callbacks(name, *args, &block)
      send("__#{name}_callback_chain", *args, &block)
    end

  end
end
