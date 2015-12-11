require 'active_support/core_ext/class/attribute'

module JSONAPIonify::Structure
  module Helpers
    module Validations
      extend ActiveSupport::Concern
      using JSONAPIonify::UnstrictProc

      module ClassMethods

        # Raise the validation errors
        def validation_error(message)
          message = "#{name}: #{message}"
          ValidationError.new(message)
        end

        # Validations

        # Fails if this key doesn't exist and the `given` does.
        def may_not_exist!(key, without: nil, **options)
          return may_not_exist_without! key, without if without
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              invalid_keys = self.keys.map(&:to_sym) & keys.map(&:to_sym)
              if invalid_keys.present?
                invalid_keys.each do |k|
                  errors.add(k, 'is not permitted')
                end
              end
            end
          end
        end

        def may_not_exist_without!(key, without, **options)
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              if has_key?(key) && !has_key?(without)
                errors.add(key, "may not exist without: `#{without}`")
              end
            end
          end
        end

        # Warn but do not fail if keys present
        def should_not_contain!(*keys, **options, &block)
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              keys         += self.keys.select(&block) if block_given?
              invalid_keys = self.keys.map(&:to_sym) & keys.map(&:to_sym)
              if invalid_keys.present?
                invalid_keys.each do |key|
                  warnings.add(key, 'is not permitted')
                end
              end
            end
          end
        end

        # Fails if these keys exist
        def must_not_contain!(*keys, deep: false, **options, &block)
          return must_not_contain_deep!(*keys, **options) if deep === true
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              keys         += self.keys.select(&block) if block_given?
              invalid_keys = self.keys.map(&:to_sym) & keys.map(&:to_sym)
              if invalid_keys.present?
                invalid_keys.each do |key|
                  errors.add(key, 'is not permitted')
                end
              end
            end
          end
        end

        # Fails if these keys exist deeply
        def must_not_contain_deep!(*keys, **options, &block)
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              all_invalid_keys = []
              keys             += self.keys.select(&block) if block_given?
              is_invalid       = proc do |hash|
                invalid_keys     = hash.keys.map(&:to_sym) & keys.map(&:to_sym)
                all_invalid_keys += invalid_keys
                children         = hash.values.select { |v| v.respond_to?(:to_hash) }
                invalid_keys.present? | children.map { |c| is_invalid.call c }.reduce(:|)
              end
              if is_invalid.call(self)
                errors.add('*', "cannot contain keys #{keys_to_sentence *all_invalid_keys.uniq}")
              end
            end
          end
        end

        # Fails if one of these keys does not exist
        def must_contain_one_of!(*keys, **options, &block)
          self.permitted_keys = [*permitted_keys, *keys].uniq
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              keys       += self.keys.select(&block) if block_given?
              valid_keys = keys.map(&:to_sym) & self.keys.map(&:to_sym)
              unless valid_keys.present?
                errors.add('*', "must contain one of: #{keys_to_sentence *valid_keys}")
              end
            end
          end
        end

        # Fails if these keys dont exist
        def must_contain!(*keys, **options)
          self.permitted_keys = [*self.permitted_keys, *keys]
          keys.each do |key|
            required_keys[key] = options
          end
        end

        # Fails if keys other than these exist
        def may_contain!(*keys)
          self.allow_only_permitted = true
          self.permitted_keys       = [*permitted_keys, *keys].uniq
        end

        # Fails is more than one of the keys exists.
        def must_not_coexist!(*keys, **options)
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
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
        def validate!(key, with: nil, message: 'is not valid', **options, &block)
          before_validation do
            if has_key? key
              JSONAPIonify::Continuation.new(**options).check(self, key, self[key]) do
                real_block = get_block_from_options(with, &block)
                errors.add key, message unless real_block.call(self, key, self[key])
              end
            end
          end
        end

        def validate_object!(with: nil, message: 'is not valid', **options, &block)
          before_validation do
            JSONAPIonify::Continuation.new(**options).check(self) do
              real_block = get_block_from_options(with, &block)
              errors.add '*', message unless real_block.call(self)
            end
          end
        end

        # Validates the object using a provided method or block
        def validate_each!(with: nil, message: 'not valid', **options, &block)
          before_validation do
            real_block = get_block_from_options(with, &block)
            keys.each do |key|
              JSONAPIonify::Continuation.new(**options).check(self, key, self[key]) do
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
      end

      # Included Stuff

      included do
        extend JSONAPIonify::InheritedAttributes
        class_attribute :allow_only_permitted, instance_writer: false
        inherited_hash_attribute :allowed_type_map, :required_keys, instance_accessor: false
        inherited_array_attribute :permitted_keys, instance_accessor: false
        self.allow_only_permitted = false
        self.permitted_keys       = []
        self.allowed_type_map     = {}
        self.required_keys        = {}

        # Check Permitted Keys
        before_validation do
          self.keys.each do |key|
            errors.add(key, "is not permitted") unless permitted_key? key
          end
        end

        # Check Permitted Types
        before_validation do
          keys.each do |key|
            next unless permitted_key?(key)
            unless permitted_type_for?(key)
              types   = permitted_types_for(key).map(&:name)
              message = "must be a #{keys_to_sentence *types}."
              errors.add(key, message)
            end
          end
        end

        # Check Required Keys
        before_validation do
          required_keys.each do |key|
            unless has_key? key
              errors.add key, 'must be provided'
            end
          end
        end

        validate_each!(message: 'is not a valid member name') do |_, key, _|
          Helpers::MemberNames.valid? key
        end

      end

      # Instance Methods

      def permitted_key?(key)
        !allow_only_permitted || permitted_keys.map(&:to_sym).include?(key.to_sym)
      end

      def required_key?(key)
        required_keys.include? key
      end

      def required_keys
        self.class.required_keys.select do |_, options|
          JSONAPIonify::Continuation.new(**options).check(self) { true }
        end.keys
      end

      def permitted_type_for?(key)
        types = permitted_types_for(key)
        types.empty? || permitted_types_for(key).any? { |type| self[key].is_a? type }
      end

      def permitted_types_for(key)
        options_and_types = allowed_type_map[key] || {}
        options_and_types.each_with_object([]) do |(options, types), permitted_types|
          JSONAPIonify::Continuation.new(**options).check(self) do
            permitted_types.concat types
          end
        end.uniq
      end

      def permitted_keys
        expand_keys(*self.class.permitted_keys)
      end

      def allowed_type_map
        self.class.allowed_type_map.dup.tap do |hash|
          wildcard_types = hash.delete('*')
          keys.each do |k|
            hash[k] ||= {}
            hash[k].deep_merge! wildcard_types
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
        raise ArgumentError, 'cannot pass symbol and block' if symbol && block
        raise ArgumentError, 'must pass symbol or block' unless symbol || block
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
end
