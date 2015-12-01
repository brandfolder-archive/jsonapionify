require 'spec_helper'
module JSONAPIonify::Structure::Maps
  # Resource Links
  # ==============
  describe ResourceLinks do
    # The optional `links` member within each [resource object][resource objects] contains [links]
    # related to the resource.
    #
    # If present, this links object **MAY** contain a `self` [link][links] that
    # identifies the resource represented by the resource object.
    #
    # ```json
    # // ...
    # {
    #   "type": "articles",
    #   "id": "1",
    #   "attributes": {
    #     "title": "Rails is Omakase"
    #   },
    #   "links": {
    #     "self": "http://example.com/articles/1"
    #   }
    # }
    # // ...
    # ```
    #
    # A server **MUST** respond to a `GET` request to the specified URL with a
    # response that includes the resource as the primary data.
  end
end
