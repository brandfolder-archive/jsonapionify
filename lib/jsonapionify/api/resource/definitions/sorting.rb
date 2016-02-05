module JSONAPIonify::Api
  module Resource::Definitions::Sorting

    class SortField

      attr_reader :name, :order

      def initialize(name)
        if name.to_s.start_with? '-'
          @name  = name.to_s[1..-1].to_sym
          @order = :desc
        else
          @name  = name
          @order = :asc
        end
      end

    end

    def self.extended(klass)
      klass.class_eval do
        inherited_hash_attribute :sorting_strategies
        context(:sort_params, readonly: true) do |context|
          should_error = false
          fields       = context.params['sort'].to_s.split(',')
          fields.each_with_object([]) do |field, array|
            field, resource = field.split('.').map(&:to_sym).reverse
            if self.class <= self.class.api.resource(resource || self.class.type)
              if self.class.field_valid? field
                array << SortField.new(field)
              else
                should_error = true
                error :sort_parameter_invalid do
                  detail "resource `#{context.resource.class.type}` does not have field: #{field}"
                end
              end
            end
          end.tap do
            raise Errors::RequestError if should_error
          end
        end

        define_sorting_strategy('Object') do |collection|
          collection
        end

        define_sorting_strategy('Enumerable') do |collection, fields|
          fields.reverse.reduce(collection) do |o, field|
            result = o.sort_by(&field.name)
            case field.order
            when :asc
              result
            when :desc
              result.reverse
            end
          end
        end

        define_sorting_strategy('ActiveRecord::Relation') do |collection, fields|
          order_hash = fields.each_with_object({}) do |field, hash|
            hash[field.name] = field.order
          end
          collection.order order_hash
        end

      end
    end

    def define_sorting_strategy(mod, &block)
      sorting_strategies[mod.to_s] = block
    end

    def default_sort(options)
      context(:default_sort, readonly: true) do
        case options
        when Hash, Array
          options.map do |k, v|
            v.to_s.downcase == 'asc' ? "-#{k}" : k.to_s
          end.join(',')
        else
          options.to_s
        end
      end
    end

    def enable_sorting(default: nil)
      default_sort default
      param :sort
      context :sorted_collection do |context|
        _, block = sorting_strategies.to_a.reverse.to_h.find do |mod, _|
          Object.const_defined?(mod, false) && context.collection.class <= Object.const_get(mod, false)
        end
        context.params['sort'] ||= context.default_sort
        context.reset(:sort_params)
        Object.new.instance_exec(context.collection, context.sort_params, &block)
      end
    end

  end
end
