module JSONAPIonify::Structure
  module Maps
    class Relationships < Base

      # The value of the relationships key MUST be an object (a "relationships object"). Members of the relationships object ("relationships") represent references from the resource object in which it's defined to other resource objects.
      # Relationships may be to-one or to-many.

      # A relationship object that represents a to-many relationship MAY also contain pagination links under the links member, as described below.
      # A resource object's AttributesObject and its RelationshipsObject are collectively called its fields.
      # Fields for a ResourceObject **MUST** share a common namespace with each
      # other and with `type` and `id`. In other words, a resource can not have an
      # attribute and relationship with the same name, nor can it have an attribute
      # or relationship named `type` or `id`.
      must_not_contain! :type, :id
      validate_each! message: 'conflicts with a resource_key' do |obj, key, _|
        !obj.parent || !obj.parent.attribute_keys.include?(key)
      end

      value_is Objects::Relationship, strict: true

    end
  end
end
