module JSONAPIonify::Api
  module Base::Delegation

    def self.extended(klass)
      klass.class_eval do
        class << self
          delegate :context, :response_header, :helper, :rescue_from, :error,
                   :enable_pagination, :before, :param, :request_header,
                   :define_pagination_strategy, :define_sorting_strategy,
                   :sticky_params, :authentication, :on_exception,
                   :example_id_generator, :after, :builder,
                   to: :resource_class

          # Delegate anything we missed
          def method_missing(m, *args, &block)
            return super unless resource_class.respond_to?(m)
            resource_class.send(m, *args, &block)
          end
        end
      end
    end

  end
end
