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

    STRATEGIES         = {
      active_record: proc { |collection, fields|
        order_hash = fields.each_with_object({}) do |field, hash|
          hash[field.name] = field.order
        end
        collection.order order_hash
      },
      enumerable:    proc { |collection, fields|
        fields.reverse.reduce(collection) do |o, field|
          result = o.sort_by(&field.name)
          case field.order
          when :asc
            result
          when :desc
            result.reverse
          end
        end
      }
    }
    STRATEGIES[:array] = STRATEGIES[:enumerable]
    DEFAULT            = STRATEGIES[:enumerable]

    def self.extended(klass)
      klass.class_eval do

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
                  detail "resource `#{self.class.type}` does not have field: #{field}"
                end
              end
            end
          end.tap do
            raise Errors::RequestError if should_error
          end
        end
      end
    end

    def sorting(strategy = nil, &block)
      param :sort
      context :sorted_collection do |context|
        unless (actual_block = block)
          actual_strategy = strategy || self.class.default_strategy
          actual_block    = actual_strategy ? STRATEGIES[actual_strategy] : DEFAULT
        end
        Object.new.instance_exec(context.collection, context.sort_params, &actual_block)
      end
    end

    private

    def default_sort
      api.resource_definitions.keys.each_with_object({}) { |type, h| h[type] = [] }
    end

  end
end
