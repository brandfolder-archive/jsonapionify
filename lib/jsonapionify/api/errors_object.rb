require 'active_support/core_ext/module/delegation'

module JSONAPIonify
  module Api
    class ErrorsObject

      delegate :present?, to: :collection

      Structure::Objects::Error.permitted_keys.each do |key|
        define_method(key) do |value|
          latest_error[key] = value
        end
      end

      def evaluate(**options, &block)
        new_error
        options.each do |k, v|
          public_send(k, v)
        end
        instance_eval(&block)
      end

      def top_level
        JSONAPIonify.new_object.tap do |obj|
          obj[:errors] = collection
        end
      end

      def meta
        JSONAPIonify::Structure::Helpers::MetaDelegate.new latest_error
      end

      def collection
        @collection ||= Structure::Collections::Errors.new
      end

      def pointer(value)
        latest_error[:source]           ||= {}
        latest_error[:source][:pointer] = value
      end

      def parameter(value)
        latest_error[:source]             ||= {}
        latest_error[:source][:parameter] = value
      end

      def set(collection)
        @collection = collection
      end

      private

      def latest_error
        collection.last || new_error
      end

      def new_error
        (collection << Structure::Objects::Error.new).last
      end

    end
  end
end