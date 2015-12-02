require 'spec_helper'
module JSONAPIonify::Structure::Objects
  describe Source do
    include JSONAPIObjects
    # Source objects may optionally including any of the following members:
    # * `pointer`: a JSON Pointer [[RFC6901](https://tools.ietf.org/html/rfc6901)]
    #   to the associated entity in the request document [e.g. `"/data"` for a
    #   primary data object, or `"/data/attributes/title"` for a specific attribute].
    # * `parameter`: a string indicating which URI query parameter caused
    #   the error.
    describe 'may contain' do
      schema = {
        pointer: 'data/1/id',
        parameter: 'something'
      }
      it_should_behave_like 'valid jsonapi object given schema', schema
    end

    describe 'invalid key' do
      it_should_behave_like 'an invalid jsonapi object', foo: 'bar'
    end

  end
end
