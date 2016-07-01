module JSONAPIonify::Structure
  module Objects
    class ResourceIdentifier < Base

      define_order :type, :id

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
        parent.select { |peer| peer == self }.length > 1
      end

      def duplicate_does_not_exist?
        !duplicate_exists?
      end

      def hash
        { type: self[:type], id: self[:id] }.hash
      end

      def eql?(other)
        other.hash == self.hash
      end

    end
  end
end
