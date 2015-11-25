module JSONAPIObjects
  module Validations
    extend ActiveSupport::Concern
    using UnstrictProc

    module ClassMethods
      # Raise the validation errors
      def validation_error(message)
        message = "#{name}: #{message}"
        ValidationError.new(message)
      end

      def inherited(subclass)
        vars = %i{
          permitted_keys
          allowed_type_map
          implementations
          collections
        }
        vars.each do |var|
          subclass.send "#{var}=", send(var).dup
        end
      end

      # Validations

      # Fails if this key doesn't exist and the `given` does.
      def may_not_exist!(key, without: nil, **options)
        return may_not_exist_without! key, without if without
        before_compile do
          Continuation.new(**options).check(self) do
            invalid_keys = self.keys.map(&:to_sym) & keys.map(&:to_sym)
            if invalid_keys.present?
              invalid_keys.each do |k|
                errors.add(k, 'is not permitted.')
              end
            end
          end
        end
      end

      def may_not_exist_without!(key, without, **options)
        before_compile do
          Continuation.new(**options).check(self) do
            if has_key?(key) && !has_key?(without)
              errors.add(key, "may not exist without: `#{without}`.")
            end
          end
        end
      end

      # Warn but do not fail if keys present
      def should_not_contain!(*keys, **options, &block)
        before_compile do
          Continuation.new(**options).check(self) do
            keys         += self.keys.select(&block) if block_given?
            invalid_keys = self.keys.map(&:to_sym) & keys.map(&:to_sym)
            if invalid_keys.present?
              invalid_keys.each do |key|
                errors.add(key, 'is not permitted.')
              end
            end
          end
        end
      end

      # Fails if these keys exist
      def must_not_contain!(*keys, deep: false, **options, &block)
        return must_not_contain_deep!(*keys, **options) if deep === true
        before_compile do
          Continuation.new(**options).check(self) do
            keys         += self.keys.select(&block) if block_given?
            invalid_keys = self.keys.map(&:to_sym) & keys.map(&:to_sym)
            if invalid_keys.present?
              invalid_keys.each do |key|
                errors.add(key, 'is not permitted.')
              end
            end
          end
        end
      end

      # Fails if these keys exist deeply
      def must_not_contain_deep!(*keys, **options, &block)
        before_compile do
          Continuation.new(**options).check(self) do
            keys       += self.keys.select(&block) if block_given?
            is_invalid = proc do |hash|
              invalid_keys = hash.keys.map(&:to_sym) & keys.map(&:to_sym)
              children     = hash.values.select { |v| v.respond_to?(:to_hash) }
              invalid_keys.present? | children.map { |c| is_invalid(c) }.reduce(:|)
            end
            if is_invalid.call(self)
              errors.add('*', "cannot contain keys #{keys_to_sentence *invalid_keys}.")
            end
          end
        end
      end

      # Fails if one of these keys does not exist
      def must_contain_one_of!(*keys, **options, &block)
        self.permitted_keys = [*permitted_keys, *keys].uniq
        before_compile do
          Continuation.new(**options).check(self) do
            keys       += self.keys.select(&block) if block_given?
            valid_keys = keys.map(&:to_sym) & self.keys.map(&:to_sym)
            unless valid_keys.present?
              errors.add('*', "must contain one of: #{keys_to_sentence *valid_keys}.")
            end
          end
        end
      end

      # Fails if these keys dont exist
      def must_contain!(*keys, **options)
        self.permitted_keys = [*self.permitted_keys, *keys]
        before_compile do
          Continuation.new(**options).check(self) do
            keys         = expand_keys(*keys)
            missing_keys = keys.map(&:to_sym) - self.keys.map(&:to_sym)
            if (origin.nil? || origin == self.origin) && missing_keys.present?
              missing_keys.each do |key|
                errors.add key, 'must be provided.'
              end
            end
          end
        end
      end

      # Fails if keys other than these exist
      def may_contain!(*keys)
        self.allow_only_permitted = true
        self.permitted_keys       = [*permitted_keys, *keys].uniq
      end

      # Fails is more than one of the keys exists.
      def must_not_coexist!(*keys, **options)
        before_compile do
          Continuation.new(**options).check(self) do
            keys             = expand_keys(*keys)
            conflicting_keys = keys & self.keys
            if conflicting_keys.length > 1
              conflicting_keys.each do |key|
                conflicts_with = conflicting_keys - [key]
                errors.add key, "conflicts with #{keys_to_sentence *conflicts_with}"
              end
            end
          end
        end
      end

      # Validates key using a provided method or block
      def validate!(key, with: nil, message: 'is not valid.', **options, &block)
        before_compile do
          Continuation.new(**options).check(self, key, self[key]) do
            real_block = get_block_from_options(with, &block)
            errors.add key, message unless real_block.call(self, key)
          end
        end
      end

      def validate_object!(with: nil, message: 'is not valid.', **options, &block)
        before_compile do
          Continuation.new(**options).check(self) do
            real_block = get_block_from_options(with, &block)
            errors.add '*', message unless real_block.call(self)
          end
        end
      end

      # Validates the object using a provided method or block
      def validate_each!(with: nil, message: 'not valid.', **options, &block)
        before_compile do
          real_block = get_block_from_options(with, &block)
          keys.each do |key|
            Continuation.new(**options).check(self, key, self[key]) do
              errors.add key, message unless real_block.call(self, key, self[key])
            end
          end
        end
      end

      # Validates key is type
      def type_of!(key, must_be:, allow_nil: false, **options)
        allowed_type_map[key] ||= {}
        types                 = Array.wrap(must_be)
        types << NilClass if allow_nil
        allowed_type_map[key][options] ||= []
        allowed_type_map[key][options] += types
      end

      private

      def before_compile(&block)
        set_callback :compile, :before, &block
      end
    end

    included do
      attr_reader :errors
      delegate :validation_error, to: :class
      class_attribute :allow_only_permitted, :implementations, :collections, instance_writer: false
      class_attribute :allowed_type_map, :permitted_keys, instance_accessor: false
      self.allow_only_permitted = false
      self.permitted_keys       = []
      self.allowed_type_map     = {}

      # Check Permitted Keys
      before_compile do
        unpermitted_keys = self.keys.map(&:to_sym) - permitted_keys.map(&:to_sym)
        if allow_only_permitted && unpermitted_keys.present?
          unpermitted_keys.each do |key|
            errors.add(key, "is not permitted")
          end
        end
      end

      # Check Permitted Types
      before_compile do
        allowed_type_map.each do |key, options_and_types|
          next unless has_key? key
          options_and_types.each do |options, types|
            Continuation.new(**options).check(self) do
              value   = self[key]
              message = "must be a #{keys_to_sentence *types.map(&:name)}."
              unless types.any? { |type| value.is_a? type }
                errors.add(key, message)
              end
            end
          end
        end
      end

      validate_each!(message: 'is not a valid member name') do |_, key, _|
        MemberNames.valid? key
      end

      # Setup Errors
      set_callback :initialize, :before do
        @errors = Errors.new
      end
    end

    def all_errors
      errors.dup.tap do |all_errors|
        object.each do |key, value|
          next unless value.respond_to? :all_errors
          value.all_errors.each do |error_key, message|
            all_errors[[key, error_key].join('.')] = message
          end
        end
      end
    end

    def permitted_keys
      expand_keys(*self.class.permitted_keys)
    end

    def allowed_type_map
      self.class.allowed_type_map.dup.tap do |hash|
        wildcard_types = hash.delete('*')
        keys.each do |k|
          hash[k] ||= []
          hash[k].deep_merge wildcard_types
          hash[k].uniq!
        end if wildcard_types.present?
      end
    end

    private

    def expand_keys(*keys)
      keys.flat_map do |key|
        key.is_a?(Proc) ? keys.select(&key) : key
      end
    end

    def get_block_from_options(symbol, &block)
      raise ArgumentError, 'cannot pass symbol and block.' if symbol && block
      raise ArgumentError, 'must pass symbol or block.' unless symbol || block
      (block || method(symbol).to_proc).unstrict
    end

    def keys_to_sentence(*keys, connector: "or")
      keys = keys.map { |key| backtick_key key }
      keys.to_sentence(last_word_connector: ", #{connector} ", two_words_connector: " #{connector} ")
    end

    def backtick_key(key)
      "`#{key}`"
    end
  end
end
