require 'active_support/concern'

module JSONAPIonify::Api
  module Resource::Callbacks
    extend ActiveSupport::Concern
    using JSONAPIonify::DestructuredProc
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
              value = begin
                instance_exec(*args, @__context, &block&.destructure)
              rescue => e
                e.backtrace.unshift block.source_location.join(':') + ":in `(callback)`"
                raise e
              end
              value if send(chains[:after], *args) != false
            end
          end unless method_defined? chains[:main]

          # Define before and after chains
          %i{after before}.each do |timing|
            define_method chains[timing] { |*| } unless method_defined? chains[timing]
            callback_name = "#{timing}_#{name}"
            define_singleton_method callback_name do |sym = nil, &outer_block|
              outer_block = (outer_block || sym).to_proc
              prev_chain  = instance_method(chains[timing])
              define_method chains[timing] do |*args, &block|
                begin
                  if prev_chain.bind(self).call(*args, @__context, &block&.destructure) != false
                    instance_exec(*args, @__context, &outer_block&.destructure)
                  end
                rescue => e
                  e.backtrace.unshift outer_block.source_location.join(':') + ":in `(callback) #{callback_name}`"
                  raise e
                end
              end
            end
          end

          private(*chains.values)

        end
      end
    end

    def run_callbacks(name, *args, &block)
      send("__#{name}_callback_chain", *args, &block)
    end

  end
end
