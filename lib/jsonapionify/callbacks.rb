require 'active_support/concern'
require 'unstrict_proc'

module JSONAPIonify
  module Callbacks
    using UnstrictProc
    extend ActiveSupport::Concern
    CallbackHalted = Class.new StandardError

    module ClassMethods
      def define_callbacks(*names)
        names.each &method(:define_callback).to_proc
      end

      def define_callback(name)
        return if method_defined? "get_#{name}_callbacks"
        memo_name = "__#{name}_callbacks__"
        define_singleton_method memo_name do
          instance_variable_get("@#{memo_name}") ||
            instance_variable_set("@#{memo_name}", {
              before: [],
              after: []
            })
        end

        %i{before after}.each do |placement|
          define_singleton_method "#{placement}_#{name}" do |*symbols, &block|
            callbacks = send(memo_name)[placement]
            callbacks.concat symbols
            callbacks << block if block
          end
        end

        # Fetch callbacks for a given name
        define_singleton_method "get_#{name}_callbacks" do
          return send(memo_name).dup.freeze unless superclass.respond_to?("get_#{name}_callbacks")
          super_callbacks = superclass.send("get_#{name}_callbacks")
          %i{before after}.each_with_object({}) do |placement, hash|
            hash[placement] = super_callbacks[placement] + send(memo_name)[placement]
          end.freeze
        end
      end
    end

    def run_callbacks(name, *args, &block)
      callbacks = self.class.send("get_#{name}_callbacks")

      # Run the before callbacks
      callbacks[:before].reduce(true) do |iterator, callable|
        iterator != false && instance_exec(*args, &callable) != false
      end != false || fail(CallbackHalted)

      # Define the return value and the after callbacks
      block.call.tap do
        callbacks[:after].reduce(true) do |iterator, callable|
          iterator != false && instance_exec(*args, &callable) != false
        end != false || fail(CallbackHalted)
      end

    rescue CallbackHalted
      false
    end

  end
end
