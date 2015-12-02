require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Meta Information
  # ================
  describe Meta do
    include JSONAPIObjects
    # Where specified, a `meta` member can be used to include non-standard
    # meta-information. The value of each `meta` member **MUST** be an object (a
    # "meta object").
    #
    # Any members **MAY** be specified within `meta` objects.
    context 'may contain any member' do
      schema   = {
        a: 1,
        b: {},
        c: [],
        d: 'string'
      }
      it_should_behave_like 'valid jsonapi object given schema', schema
    end
  end
end
