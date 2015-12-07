require 'jsonapionify/unstrict_proc'

module JSONAPIonify
  module EnumerableObserver
    using UnstrictProc

    def self.observe(obj)
      Observer.new(obj)
    end

    def observe(obj = self)
      Observer.new(obj)
    end

    class Observer
      using UnstrictProc

      UNSAFE_METHODS = %i{
        instance_variable_set
        remove_instance_variable
        define_singleton_method
        instance_eval
        instance_exec
      }
      SAFE_METHODS   = (%i{each} + Object.instance_methods) - UNSAFE_METHODS

      private def observer_method_proc(existing = [])
        array = [self, *existing].freeze
        lambda do
          array
        end
      end

      def initialize(obj)
        @object        = obj
        observers_proc =
          observer_method_proc(obj.respond_to?(:observers) ? obj.observers : [])
        obj.define_singleton_method(:observers, &observers_proc)
        obj.extend mod
      end

      def mod
        @mod ||= begin
          obj    = @object
          blocks = self.blocks
          Module.new do
            (obj.methods - SAFE_METHODS).each do |meth|
              old = obj.method(meth).unbind.bind(obj)
              define_method(meth) do |*args, &block|
                before  = each.to_a
                val     = old.call(*args, &block)
                after   = each.to_a
                added   = after - before
                removed = before - after
                blocks[:add].unstrict.call(added) unless added.empty? || !blocks[:add]
                blocks[:remove].unstrict.call(removed) unless removed.empty? || !blocks[:remove]
                val
              end
            end
          end
        end
      end

      def unobserve
        mod.instance_methods.each do |method_name|
          mod.module_eval do
            remove_method method_name
          end
        end
        @unobserved = true
      end

      def added(&block)
        blocks[:add] = block
        self
      end

      def removed(&block)
        blocks[:remove] = block
        self
      end

      protected

      def blocks
        @blocks ||= {}
      end

    end
  end
end
