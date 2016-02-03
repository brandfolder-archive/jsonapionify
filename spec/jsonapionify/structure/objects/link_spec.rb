require 'spec_helper'
module JSONAPIonify::Structure::Objects
  describe Link do
    include JSONAPIObjects
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
    describe 'must be a valid url' do
      context 'when valid' do
        data = { href: "https://google.com/foo" }
        it_should_behave_like 'a valid jsonapi object', data
      end

      context 'when not valid' do
        data = { href: "foo" }
        it_should_behave_like 'an invalid jsonapi object', data
      end
    end

    describe 'may contain' do
      schema = {
        href: 'http://google.com',
        meta: {}
      }
      it_should_behave_like 'valid jsonapi object given schema', schema
    end
  end
end
