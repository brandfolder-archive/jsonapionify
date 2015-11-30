module JSONAPIObjects
  # ResourceObjects appear in a JSON API document to represent resources.
  class ResourceObject < ResourceIdentifierObject
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

    # Note: This spec is agnostic about inflection rules, so the value of `type`
    # can be either plural or singular. However, the same value should be used
    # consistently throughout an implementation.
    def attribute_keys
      return [] unless self[:attributes]
      self[:attributes].keys
    end

    def relationship_keys
      return [] unless self[:relationships]
      self[:relationships].keys
    end

  end
end
