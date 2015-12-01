require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Error Objects
  # =============
  describe Error do
    include JSONAPIObjects
    # Error objects provide additional information about problems encountered while
    # performing an operation. Error objects **MUST** be returned as an array
    # keyed by `errors` in the top level of a JSON API document.
    #
    # An error object **MAY** have the following members:
    context 'may contain' do
      schema   = {
        id:     "1", # a unique identifier for this particular occurrence of the problem.
        links:  {}, # a links object
        status: "OK", # the HTTP status code applicable to this problem, expressed as a string value.
        code:   "200", # an application-specific error code, expressed as a string value.
        title:  "something", # a short, human-readable summary of the problem that **SHOULD NOT** change from occurrence to occurrence of the problem, except for purposes of localization.
        detail: "something details", # a human-readable explanation specific to this occurrence of the problem.
        source: {}, # an object containing references to the source of the error.
        meta:   {} # a [meta object][meta] containing non-standard meta-information about the
      }
      comboset = keycombos(schema.keys)
      comboset.each do |combos|
        combos.each do |keys|
          data = schema.slice(*keys)
          it_should_behave_like 'a valid jsonapi object', data
        end
      end
    end

    context 'invalid key' do
      it_should_behave_like 'an invalid jsonapi object', foo: 'bar'
    end
  end
end
