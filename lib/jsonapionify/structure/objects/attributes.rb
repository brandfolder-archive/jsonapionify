module JSONAPIonify::Structure
  module Objects
    class Attributes < Base

      # Attributes may contain any valid JSON value.
      # Complex data structures involving JSON objects and arrays are allowed as
      # attribute values. However, any object that constitutes or is contained in an
      # attribute **MUST NOT** contain a `relationships` or `links` member, as those
      # members are reserved by this specification for future use.
      must_not_contain! :relationships, :links, deep: true

      # A resource object's AttributesObject and its RelationshipsObject are collectively called its fields.
      # Fields for a ResourceObject **MUST** share a common namespace with each
      # other and with `type` and `id`. In other words, a resource can not have an
      # attribute and relationship with the same name, nor can it have an attribute
      # or relationship named `type` or `id`.
      must_not_contain! :type, :id
      validate_each! message: 'conflicts with a relationship key' do |obj, key, _|
        !obj.parent || !obj.parent.relationship_keys.include?(key) rescue binding.pry
      end

      # Although has-one foreign keys (e.g. `author_id`) are often stored internally
      # alongside other information to be represented in a resource object, these keys
      # **SHOULD NOT** appear as attributes.
      should_not_contain! { |key| key.to_s.end_with? '_id' }

    end
  end
end
