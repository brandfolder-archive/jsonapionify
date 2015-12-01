module JSONAPIonify::Structure
  module Helpers
    module InheritsOrigin
      def client?
        origin == :client
      end

      def server?
        origin == :server
      end

      def origin
        self.parent.try(:origin)
      end
    end
  end
end
