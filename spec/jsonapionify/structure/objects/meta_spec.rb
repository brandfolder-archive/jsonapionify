require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Meta Information
  # ================
  describe Meta do
    # Where specified, a `meta` member can be used to include non-standard
    # meta-information. The value of each `meta` member **MUST** be an object (a
    # "meta object").
    #
    # Any members **MAY** be specified within `meta` objects.
    #
    # For example:
    #
    # ```javascript
    # {
    #   "meta": {
    #     "copyright": "Copyright 2015 Example Corp.",
    #     "authors": [
    #       "Yehuda Katz",
    #       "Steve Klabnik",
    #       "Dan Gebhardt",
    #       "Tyler Kellen"
    #     ]
    #   },
    #   "data": {
    #     // ...
    #   }
    # }
    # ```
  end
end
