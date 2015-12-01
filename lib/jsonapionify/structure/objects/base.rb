require 'active_support/core_ext/module/delegation'
require 'active_support/callbacks'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/hash/keys'

module JSONAPIonify::Structure
  module Objects
    class Base
      include Enumerable
      include JSONAPIonify::EnumerableObserver
      include ActiveSupport::Callbacks
      include Helpers::InheritsOrigin
      define_callbacks :compile, :initialize

      include Helpers::ObjectSetters
      include Helpers::Validations
      include Helpers::ObjectDefaults

      # Attributes
      attr_reader :object, :parent

      delegate :select, :has_key?, :keys, :values, :each, :present?, :blank?, :empty?, to: :object

      set_callback :initialize, :before do
        @object = {}
        observe(@object, added: ->(_, items) {
          items.each do |_, value|
            value.instance_variable_set(:@parent, self) unless value.frozen?
          end
        })
      end

      def self.from_hash(hash)
        new hash.deep_symbolize_keys
      end

      def self.from_json(json)
        from_hash JSON.load json
      end

      # Initialize the object
      def initialize(**attributes)
        run_callbacks :initialize do
          attributes.each do |k, v|
            self[k] = v
          end
        end
      end

      def copy
        self.class.from_hash to_hash
      end

      # Compile as json
      attr_reader :errors, :warnings

      def as_json(*args)
        compile(*args)
      end

      def compile(*args)
        @errors   = Helpers::Errors.new
        @warnings = Helpers::Errors.new
        run_callbacks :compile do
          object.as_json(*args)
        end
      end

      def compile!(*args)
        compile(*args).tap do
          if (wrns = all_warnings).present?
            warn validation_error wrns.all_messages.to_sentence + '.'
          end
          if (errs = all_errors).present?
            raise validation_error errs.all_messages.to_sentence + '.'
          end
        end
      end

      def pretty_json(*args)
        JSON.pretty_generate as_json(*args)
      end

      def to_hash
        compile.deep_symbolize_keys
      end

    end
  end
end
