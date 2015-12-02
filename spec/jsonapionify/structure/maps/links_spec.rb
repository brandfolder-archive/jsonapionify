require 'spec_helper'
module JSONAPIonify::Structure::Maps
  # Links
  # =====
  describe Links do
    include JSONAPIObjects
    # Where specified, a `links` member can be used to represent links. The value
    # of each `links` member **MUST** be an object (a "links object").
    #
    # Each member of a links object is a "link". A link **MUST** be represented as
    # either:
    #
    # * a string containing the link's URL.
    # * an object ("link object").
    describe 'must be a string or link object' do
      context 'when a string' do
        it_should_behave_like 'a valid jsonapi object', foo: 'http://google.com'
      end

      context 'when a links object' do
        it_should_behave_like 'a valid jsonapi object', foo: { href: 'http://google.com' }
      end

      context 'when a something else' do
        it_should_behave_like 'an invalid jsonapi object', foo: 1
      end
    end
  end
end
