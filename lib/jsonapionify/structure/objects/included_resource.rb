module JSONAPIonify::Structure
  module Objects
    # ResourceObjects appear in a JSON API document to represent resources.
    class IncludedResource < Resource
      validate_object! with: :referenced?, message: "included resource is not referenced"

      def referenced?
        return true unless parent
        parent.referenced.include? self
      end

    end
  end
end
