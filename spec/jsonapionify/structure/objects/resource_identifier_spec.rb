require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Resource Identifier Objects
  # ===========================
  describe ResourceIdentifier do
    include_context 'resource identification'
    # A "resource identifier object" is an object that identifies an individual
    # resource.
    #
    # A "resource identifier object" **MUST** contain `type` and `id` members.
    #
    # A "resource identifier object" **MAY** also include a `meta` member, whose value is a [meta] object that
    # contains non-standard meta-information.
    #
    # ### <a href="#document-compound-documents" id="document-compound-documents" class="headerlink"></a> Compound Documents
    #
    # To reduce the number of HTTP requests, servers **MAY** allow responses that
    # include related resources along with the requested primary resources. Such
    # responses are called "compound documents".
    #
    # In a compound document, all included resources **MUST** be represented as an
    # array of [resource objects] in a top-level `included` member.
    #
    # Compound documents require "full linkage", meaning that every included
    # resource **MUST** be identified by at least one [resource identifier object]
    # in the same document. These resource identifier objects could either be
    # primary data or represent resource linkage contained within primary or
    # included resources. The only exception to the full linkage requirement is
    # when relationship fields that would otherwise contain linkage data are
    # excluded via [sparse fieldsets](#fetching-sparse-fieldsets).
    #
    # > Note: Full linkage ensures that included resources are related to either
    # the primary data (which could be [resource objects] or [resource identifier
    # objects][resource identifier object]) or to each other.
    #
    # A complete example document with multiple included relationships:
    #
    # ```json
    # {
    #   "data": [{
    #     "type": "articles",
    #     "id": "1",
    #     "attributes": {
    #       "title": "JSON API paints my bikeshed!"
    #     },
    #     "links": {
    #       "self": "http://example.com/articles/1"
    #     },
    #     "relationships": {
    #       "author": {
    #         "links": {
    #           "self": "http://example.com/articles/1/relationships/author",
    #           "related": "http://example.com/articles/1/author"
    #         },
    #         "data": { "type": "people", "id": "9" }
    #       },
    #       "comments": {
    #         "links": {
    #           "self": "http://example.com/articles/1/relationships/comments",
    #           "related": "http://example.com/articles/1/comments"
    #         },
    #         "data": [
    #           { "type": "comments", "id": "5" },
    #           { "type": "comments", "id": "12" }
    #         ]
    #       }
    #     }
    #   }],
    #   "included": [{
    #     "type": "people",
    #     "id": "9",
    #     "attributes": {
    #       "first-name": "Dan",
    #       "last-name": "Gebhardt",
    #       "twitter": "dgeb"
    #     },
    #     "links": {
    #       "self": "http://example.com/people/9"
    #     }
    #   }, {
    #     "type": "comments",
    #     "id": "5",
    #     "attributes": {
    #       "body": "First!"
    #     },
    #     "relationships": {
    #       "author": {
    #         "data": { "type": "people", "id": "2" }
    #       }
    #     },
    #     "links": {
    #       "self": "http://example.com/comments/5"
    #     }
    #   }, {
    #     "type": "comments",
    #     "id": "12",
    #     "attributes": {
    #       "body": "I like XML better"
    #     },
    #     "relationships": {
    #       "author": {
    #         "data": { "type": "people", "id": "9" }
    #       }
    #     },
    #     "links": {
    #       "self": "http://example.com/comments/12"
    #     }
    #   }]
    # }
    # ```
    #
    # A [compound document] **MUST NOT** include more than one [resource object][resource objects] for
    # each `type` and `id` pair.
    #
    # > Note: In a single document, you can think of the `type` and `id` as a
    # composite key that uniquely references [resource objects] in another part of
    # the document.
    #
    # > Note: This approach ensures that a single canonical [resource object][resource objects] is
    # returned with each response, even when the same resource is referenced
    # multiple times.
  end
end
