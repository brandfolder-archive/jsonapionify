require 'spec_helper'
module JSONAPIonify::Structure::Objects
  describe Relationship do
    include JSONAPIObjects
    # A "relationship object" **MUST** contain at least one of the following:
    #
    # * `links`: a [links object][links] containing at least one of the following:
    #   * `self`: a link for the relationship itself (a "relationship link"). This
    #     link allows the client to directly manipulate the relationship. For example,
    #     it would allow a client to remove an `author` from an `article` without
    #     deleting the `people` resource itself.
    #   * `related`: a [related resource link]
    # * `data`: [resource linkage]
    # * `meta`: a [meta object][meta] that contains non-standard meta-information about the
    #   relationship.
    #
    # A relationship object that represents a to-many relationship **MAY** also contain
    # [pagination] links under the `links` member, as described below.
    #
    # > Note: See [fields] and [member names] for more restrictions on this container.

    # Resource Linkage
    # ================
    describe 'Resource Linkage' do
      # Resource linkage in a [compound document] allows a client to link together all
      # of the included [resource objects] without having to `GET` any URLs via [links].
      #
      # Resource linkage **MUST** be represented as one of the following:
      #
      # * `null` for empty to-one relationships.
      # * an empty array (`[]`) for empty to-many relationships.
      # * a single [resource identifier object] for non-empty to-one relationships.
      # * an array of [resource identifier objects][resource identifier object] for non-empty to-many relationships.
      #
      # > Note: The spec does not impart meaning to order of resource identifier
      # objects in linkage arrays of to-many relationships, although implementations
      # may do that. Arrays of resource identifier objects may represent ordered
      # or unordered relationships, and both types can be mixed in one response
      # object.
      #
      # For example, the following article is associated with an `author`:
      #
      # ```javascript
      # // ...
      # {
      #   "type": "articles",
      #   "id": "1",
      #   "attributes": {
      #     "title": "Rails is Omakase"
      #   },
      #   "relationships": {
      #     "author": {
      #       "links": {
      #         "self": "http://example.com/articles/1/relationships/author",
      #         "related": "http://example.com/articles/1/author"
      #       },
      #       "data": { "type": "people", "id": "9" }
      #     }
      #   },
      #   "links": {
      #     "self": "http://example.com/articles/1"
      #   }
      # }
      # // ...
      # ```
      #
      # The `author` relationship includes a link for the relationship itself (which
      # allows the client to change the related author directly), a related resource
      # link to fetch the resource objects, and linkage information.
    end
  end
end
