require 'spec_helper'
module JSONAPIonify::Structure::Maps
  # Resource Links
  # ==============
  describe ResourceLinks do
    include JSONAPIObjects
    # The optional `links` member within each resource object contains links
    # related to the resource.
    #
    # If present, this links object **MAY** contain a `self` link that
    # identifies the resource represented by the resource object.
    describe 'may contain `self`' do
      it_should_behave_like 'a valid jsonapi object', self: 'http://self.me'

      context 'invalid key' do
        it_should_behave_like 'an invalid jsonapi object', foo: 'http://self.me'
      end
    end
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
