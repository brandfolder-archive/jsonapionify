module JSONAPIObjects
  class RelationshipObject < BaseObject
    # A "relationship object" MUST contain at least one of the following:
    must_contain_one_of! :links, # A links object.
                         :data, # Resource linkage.
                         :meta # A meta object that contains non-standard meta-information about the relationship.

    implements :links, as: LinksObject
    implements :meta, as: MetaObject

    collects_or_implements :data, collects: ResourceIdentifiersCollection, implements: ResourceIdentifierObject
  end
end
