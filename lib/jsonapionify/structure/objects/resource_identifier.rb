module JSONAPIonify::Structure
  module Objects
    class ResourceIdentifier < Base
      # A resource object **MUST** contain at least the following top-level members:
      must_contain! :id, :type # Describes ResourceObjects that share common attributes and relationships.

      # Identification
      # ==============
      #
      # The values of the `id` and `type` members **MUST** be strings.
      type_of! :id, must_be: String
      type_of! :type, must_be: String

      # The values of `type` members **MUST** adhere to the same constraints as member names.
      validate!(:type, message: 'is not a valid member name') do |*, value|
        Helpers::MemberNames.valid? value
      end

      validate_object!(with: :duplicate_does_not_exist?, message: 'is not unique')

      def duplicate_exists?
        return false unless parent.is_a?(Array)
        peers = parent - [self]
        !!peers.index(self)
      end

      def ==(other)
        same_as? other
      end

      def duplicate_does_not_exist?
        !duplicate_exists?
      end

      def same_as?(other)
        return false unless other.is_a? ResourceIdentifier
        other_type, other_id = other.values_at :type, :id
        local_type, local_id = values_at :type, :id
        other_type == local_type &&
          !(other_id || local_id).nil? &&
          other_id == local_id
      end

    end
  end
end
