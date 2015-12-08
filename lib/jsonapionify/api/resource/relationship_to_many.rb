module JSONAPIonify::Api
  module Resource::RelationshipToMany
    extend ActiveSupport::Concern

    module Associate
      extend ActiveSupport::Concern
      include do
        response do

        end
      end
    end

    module Disassociate
      extend ActiveSupport::Concern
      include do
        response do

        end
      end
    end

    module ClassMethods
      def associate
        associate_action = Class.new(self).include(Associate)
        define_singleton_method :process_associate do |req|
          associate_action.new(req).response(&block)
        end
      end

      def disassociate
        disassociate_action = Class.new(self).include(Disassociate)
        define_singleton_method :process_disassociate do |req|
          disassociate_action.new(req).response(&block)
        end
      end
    end

    included do
      associate do
        resources.each do |resource|
          collection << resource
        end
      end

      disassociate do
        resources.each do |resource|
          collection.delete resource
        end
      end

      delete do
        collection.delete instance
        self.destroyed = !collection.include?(instance)
      end
    end

  end
end