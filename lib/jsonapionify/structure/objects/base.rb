require 'oj'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/hash/keys'
require 'enumerable_observer'
require 'concurrent'

module JSONAPIonify::Structure
  module Objects
    class Base

      include JSONAPIonify::Callbacks
      include Enumerable
      include EnumerableObserver
      include Helpers::InheritsOrigin

      define_callbacks :initialize, :validation

      include Helpers::ObjectSetters
      include Helpers::Validations
      include Helpers::ObjectDefaults

      # Attributes
      attr_reader :object, :parent

      delegate :cache_store, to: JSONAPIonify
      delegate(*(Hash.instance_methods - instance_methods), to: :object)

      before_initialize do
        observe(self.object).added do |items|
          items.each do |_, value|
            value.instance_variable_set(:@parent, self) unless value.frozen?
          end
        end
      end

      def self.from_hash(hash)
        new hash.deep_symbolize_keys
      end

      def self.define_order(*keys)
        define_singleton_method :ordered_keys do
          keys
        end
      end

      define_order

      def self.from_json(json)
        from_hash Oj.load json
      end

      # Initialize the object
      def initialize(**attributes)
        @object = Hash.new
        run_callbacks :initialize do
          attributes.each do |k, v|
            self[k] = v
          end
        end
      end

      def copy
        self.class.from_hash to_h
      end

      def ==(other)
        return unless other.respond_to? :[]
        object.all? do |k, v|
          other[k] == v
        end
      end

      def ===(other)
        other.class == self.class && self == other
      end

      # Compile as json
      attr_reader :errors, :warnings

      def compile(validate: true)
        self.validate if validate && !JSONAPIonify.validation_disabled?
        to_h
      end

      def as_json(**opts)
        compile(**opts).deep_stringify_keys
      end

      def to_json(**opts)
        Oj.dump as_json(**opts)
      end

      def signature
        "#{self.class.name}:#{Digest::SHA2.hexdigest to_h.to_s}"
      end

      def to_h
        ordered_object = [
          *object.slice(*self.class.ordered_keys),
          *object.except(*self.class.ordered_keys)
        ]
        ordered_object.reduce({}) do |hash, (k, v)|
          hash[k] =
            case v
            when Objects::Base
              v.to_h
            when Hash
              v.deep_stringify_keys
            when Collections::Base
              v.collect_hashes
            else
              v
            end
          hash
        end
      end

      def compile!(*args)
        compile(*args).tap do
          if (wrns = warnings).present?
            warn validation_error wrns.all_messages.to_sentence + '.'
          end
          if (errs = errors).present?
            raise validation_error errs.all_messages.to_sentence + '.'
          end
        end
      end

      def validate
        object.values.each { |val| val.validate if val.respond_to? :validate }
        [errors, warnings].each(&:clear)
        @errors, @warnings =
          cache_store.fetch(signature) do
            run_callbacks :validation do
              collect_child_errors
              collect_child_warnings
            end
            [errors, warnings]
          end
        errors.blank?
      end

      def errors
        @errors ||= Helpers::Errors.new
      end

      def warnings
        @warnings ||= Helpers::Errors.new
      end

      def pretty_json
        JSON.pretty_generate as_json
      end

      def inspect
        hash_inspect = to_h.to_s.gsub(
          /\:([a-zA-Z_-]+)=>/, '\\1: '
        )[1..-2].gsub(
          /\{([^\s])/, '{ \\1').gsub(/([^\s])\}/, '\\1 }'
        )
        to_s.sub(/>$/, " #{hash_inspect}>")
      end

      private

      def collect_child_errors
        object.each do |key, value|
          next unless value.respond_to? :errors
          value.errors.each do |error_key, messages|
            errors.replace [key, error_key].join('/'), messages
          end
        end
      end

      def collect_child_warnings
        object.each do |key, value|
          next unless value.respond_to? :warnings
          value.warnings.each do |warning_key, messages|
            warnings.replace [key, warning_key].join('/'), messages
          end
        end
      end

    end
  end
end
