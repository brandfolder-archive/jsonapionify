require 'spec_helper'
module JSONAPIonify::Structure::Maps
# Related Resource Links
# ======================
  describe RelatedResourceLinks do
    # A "related resource link" provides access to [resource objects] [linked][links]
    # in a [relationship][relationships]. When fetched, the related resource object(s)
    # are returned as the response's primary data.
    #
    # For example, an `article`'s `comments` [relationship][relationships] could
    # specify a [link][links] that returns a collection of comment [resource objects]
    # when retrieved through a `GET` request.
    #
    # If present, a related resource link **MUST** reference a valid URL, even if the
    # relationship isn't currently associated with any target resources. Additionally,
    # a related resource link **MUST NOT** change because its relationship's content
    # changes.
  end
end
