require 'active_support/concern'

module JSONAPIonify::Structure
  module Helpers
    module ObjectSetters
      extend ActiveSupport::Concern

      # Setter
      def []=(k, v)
        raise TypeError, 'key must be a Symbol.' unless k.is_a? Symbol
        object[k] = v
      end

      # Getter
      def [](k)
        raise TypeError, 'key must be a Symbol.' unless k.is_a? Symbol
        object[k]
      end
    end
  end
end
