module JSONAPIonify::Api
  module Resource::ClassMethods
    include JSONAPIonify::EnumerableObserver

    def description(string)
      # TODO: Implement Description
    end

    def set_api(api)
      self.tap do
        define_singleton_method :api do
          api
        end
      end
    end

    def set_type(type)
      type = type.to_s
      self.tap do
        define_singleton_method :type do
          type
        end
      end
    end

    def api
      nil
    end

  end
end