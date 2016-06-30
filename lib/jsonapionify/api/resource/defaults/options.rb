module JSONAPIonify::Api
  module Resource::Defaults::Options
    extend ActiveSupport::Concern
    included do
      id :id
      scope { self.type.classify.constantize }
      collection do |scope|
        if defined?(ActiveRecord) && scope.is_a?(Class) && scope < ActiveRecord::Base
          scope.all
        else
          scope
        end
      end

      instance do |scope, key|
        if defined?(ActiveRecord) && scope.is_a?(Class) && scope < ActiveRecord::Base
          scope.find_by! id_attribute => key
        else
          raise NotImplementedError, 'instance not implemented'
        end
      end

      new_instance do |scope|
        if defined?(ActiveRecord) && scope.is_a?(Class) && scope < ActiveRecord::Base
          scope.new
        else
          raise NotImplementedError, 'scope not implemented'
        end
      end

      # Invoke validating contexts
      before { |request_headers:| }

    end
  end
end
