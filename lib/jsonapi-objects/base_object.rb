require 'active_support/core_ext/module/delegation'
require 'active_support/callbacks'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/hash/keys'

module JSONAPIObjects
  class BaseObject
    include Enumerable
    include EnumerableObserver
    include ActiveSupport::Callbacks
    include InheritsOrigin
    define_callbacks :compile, :initialize

    include ObjectSetters
    include Validations
    include ObjectDefaults
    include InheritsOrigin

    # Attributes
    attr_reader :object, :parent

    delegate :has_key?, :keys, :values, :each, :present?, :blank?, :empty?, to: :object

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
    def as_json(*args)
      run_callbacks :compile do
        if (errs = all_errors).present?
          raise validation_error errs.all_messages.to_sentence
        end
        object.as_json(*args)
      end
    end

    def pretty_json(*args)
      JSON.pretty_generate as_json(*args)
    end

    alias_method :compile, :as_json
    alias_method :to_hash, :object

  end
end
