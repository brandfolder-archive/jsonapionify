module JSONAPIObjects
  # ResourceObjects appear in a JSON API document to represent resources.
  class ResourceObject < BaseObject
    # A resource object **MUST** contain at least the following top-level members:
    must_contain! :type # Describes ResourceObjects that share common attributes and relationships.

    # The `id` member is not required when the resource object originates at the
    # client and represents a new resource to be created on the server.
    must_contain! :id, if: ->(obj) { obj.server? } # an id representing the resource

    # In addition, a resource object **MAY** contain any of these top-level members:
    may_contain! :attributes, # An AttributesObject representing some of the resource's data.
                 :relationships, # A RelationshipsObject describing relationships between the resource and other JSON API resources.
                 :links, # A LinksObject containing links related to the resource.
                 :meta # A MetaObject containing non-standard meta-information about a resource that can not be represented as an attribute or relationship.

    implements :attributes, as: AttributesObject
    implements :relationships, as: RelationshipsObject
    implements :links, as: LinksObject
    implements :meta, as: MetaObject

    # Identification
    # ==============
    #
    # The values of the `id` and `type` members **MUST** be strings.
    type_of! :id, must_be: String
    type_of! :type, must_be: String

    # The values of `type` members **MUST** adhere to the same constraints as member names.
    validate!(:type, message: 'is not a valid member name') do |*, value|
      MemberNames.valid? value
    end

    validate_object!(with: :duplicate_does_not_exist?, message: 'is not unique')

    # Note: This spec is agnostic about inflection rules, so the value of `type`
    # can be either plural or singular. However, the same value should be used
    # consistently throughout an implementation.
    def attribute_keys
      return [] unless self[:attributes]
      self[:attributes].keys
    end

    def duplicate_exists?
      return false unless parent.is_a?(Array)
      peers            = parent - [self]
      peers.any? do |peer|
        matches_id   = peer.has_key?(:id) && has_key?(:id) && peer[:id] == self[:id]
        matches_type = peer[:type] == self[:type]
        matches_type && matches_id
      end
    end

    def duplicate_does_not_exist?
      !duplicate_exists?
    end

    def relationship_keys
      return [] unless self[:relationships]
      self[:relationships].keys
    end

  end
end
