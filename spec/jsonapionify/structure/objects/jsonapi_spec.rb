require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # JSON API Object
  # ===============
  describe Jsonapi do
    include JSONAPIObjects
    # A JSON API document **MAY** include information about its implementation
    # under a top level `jsonapi` member. If present, the value of the `jsonapi`
    # member **MUST** be an object (a "jsonapi object"). The jsonapi object **MAY**
    # contain a `version` member whose value is a string indicating the highest JSON
    # API version supported. This object **MAY** also contain a `meta` member, whose
    # value is a [meta] object that contains non-standard meta-information.
    context 'may contain' do
      schema = {
        version: "1.0.0",
        meta:    {}
      }
      it_should_behave_like 'valid jsonapi object given schema', schema
    end

    # If the `version` member is not present, clients should assume the server
    # implements at least version 1.0 of the specification.
    #
    # > Note: Because JSON API is committed to making additive changes only, the
    # version string primarily indicates which new features a server may support.
  end

end
