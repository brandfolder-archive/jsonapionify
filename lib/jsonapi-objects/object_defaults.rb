require 'active_support/concern'

module JSONAPIObjects
  module ObjectDefaults
    extend ActiveSupport::Concern
    include EnumerableObserver

    module ClassMethods
      # Forces the setter to a type
      def implements(key, as:, **opts)
        type_of! key, must_be: as, allow_nil: true
        track_implementation key, as, **opts
      end

      # Forces the setter to the collection type
      # Allows unset types to expose collection and type_map methods
      def collects(key, as:, **opts)
        type_of! key, must_be: as
        track_collection key, as, **opts
      end

      # implements_or_collects(:data, implements: A, collects: B, if: ->(obj){ obj.has_key? :attributes })
      # implements_or_collects(:data, implements: C, collects: D, unless: ->(obj){ obj.has_key? :attributes })
      def collects_or_implements(key, implements:, collects:, allow_nil: false, **opts)
        allowed = [implements, collects]
        allowed << NilClass if allow_nil
        type_of! key, must_be: allowed
        track_collection key, collects, **opts
        track_implementation key, implements, **opts
      end

      alias_method :implements_or_collects, :collects_or_implements

      # Defaults
      def default(key, &block)
        set_callback :initialize, :after do
          self[key] ||= instance_eval(&block)
        end
      end

      private

      def track_implementation(key, klass, **opts)
        (implementations[key] ||= {})[klass] = opts
      end

      def track_collection(key, klass, **opts)
        (collections[key] ||= {})[klass] = opts
      end
    end

    included do
      # Class Attributes
      attr_reader :unset
      class_attribute :implementations, :collections, instance_writer: false
      self.implementations = {}
      self.collections     = {}

      set_callback :initialize, :before do
        @unset = {}
      end
    end

    def [](k)
      if has_key? k
        super
      elsif collections[k]
        @unset[k] ||= [].tap do |ary|
          observe ary, added: -> {
            self[k] = ary
          }
        end
      else
        nil
      end
    end

    def []=(k, v)
      unset.delete_if { |unset_key, _| unset_key == k }
      super k, coerce_value(k, v)
    end

    def object
      super.tap do
        newly_set = unset.select { |_, v| v.present? }
        newly_set.each do |k, v|
          self[k] = v
        end
      end
    end

    private

    def coerce_value(k, v)
      if implementations[k] && v.is_a?(Hash)
        coerce_implementation(k, v)
      elsif collections[k] && v.is_a?(Array)
        coerce_collection(k, v)
      else
        v
      end
    end

    def coerce_implementation(k, v)
      klass, * = (implementations[k] || {}).find do |_, options|
        Continuation.new(**options).check(v) { true }
      end
      return v unless klass && !v.is_a?(klass)
      klass.new(v)
    end

    def coerce_collection(k, v)
      klass, * = (collections[k] || {}).find do |_, options|
        v.all? do |obj|
          Continuation.new(**options).check(obj) { true }
        end
      end
      return v unless klass && !v.is_a?(klass)
      klass.new(v)
    end

  end
end