module JSONAPIonify::Api
  module Base::Delegation

    def self.extended(klass)
      klass.class_eval do
        class << self
          delegate :context, :header, :helper, :rescue_from, :error, :pagination, to: :resource_class
        end
      end
    end

  end
end