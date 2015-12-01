require 'spec_helper'
module JSONAPIonify::Structure::Maps
  # Links
  # =====
  describe Links do
    # Where specified, a `links` member can be used to represent links. The value
    # of each `links` member **MUST** be an object (a "links object").
    #
    # Each member of a links object is a "link". A link **MUST** be represented as
    # either:
    #
    # * a string containing the link's URL.
    # * an object ("link object") which can contain the following members:
    #   * `href`: a string containing the link's URL.
    #   * `meta`: a meta object containing non-standard meta-information about the
    #     link.
    #
    # The following `self` link is simply a URL:
    #
    # ```json
    # "links": {
    #   "self": "http://example.com/posts",
    # }
    # ```
    #
    # The following `related` link includes a URL as well as meta-information
    # about a related resource collection:
    #
    # ```json
    # "links": {
    #   "related": {
    #     "href": "http://example.com/articles/1/comments",
    #     "meta": {
    #       "count": 10
    #     }
    #   }
    # }
    # ```
    #
    # > Note: Additional members may be specified for links objects and link
    # objects in the future. It is also possible that the allowed values of
    # additional members will be expanded (e.g. a `collection` link may support an
    # array of values, whereas a `self` link does not).
  end
end
