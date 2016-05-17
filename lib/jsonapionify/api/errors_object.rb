require 'active_support/core_ext/module/delegation'

module JSONAPIonify
  module Api
    class ErrorsObject

      delegate :present?, to: :collection

      class Evaluator
        Structure::Objects::Error.permitted_keys.each do |key|
          define_method(key) do |value|
            @error[key] = value
          end
        end

        def initialize(error)
          @error = error
          freeze
        end

        def meta
          JSONAPIonify::Structure::Helpers::MetaDelegate.new @error
        end

        def pointer(value)
          @error[:source]           ||= {}
          @error[:source][:pointer] = value
        end

        def parameter(value)
          @error[:source]             ||= {}
          @error[:source][:parameter] = value
        end
      end

      def evaluate(*args, error_block:, runtime_block: nil, backtrace: nil)
        backtrace     ||= caller
        runtime_block ||= proc {}
        error         = Structure::Objects::Error.new
        evaluator     = Evaluator.new(error)
        collection << error
        [runtime_block, error_block].each do |block|
          evaluator.instance_exec(*args, &block) if block
        end
        if JSONAPIonify.show_backtrace == true
          error[:meta]             ||= {}
          error[:meta][:backtrace] = backtrace
        end
      end

      def top_level
        JSONAPIonify.new_object.tap do |obj|
          obj[:errors] = collection
        end
      end

      def collection
        @collection ||= Structure::Collections::Errors.new
      end

      def set(collection)
        @collection = collection
      end

    end
  end
end
