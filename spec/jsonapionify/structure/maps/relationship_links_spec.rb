require 'spec_helper'
module JSONAPIonify::Structure::Maps
  describe RelationshipLinks do
    include JSONAPIObjects
    # The RelationshipLinksObject **MAY** contain the following members:
    # * self: the link that generated the current response document.
    # * related: a related resource link when the primary data represents a resource relationship.
    describe 'must contain one of' do
      it_should_behave_like 'valid jsonapi object given keys', %i{self related}, 'http://self.me'

      describe 'may contain' do
        it_should_behave_like 'valid jsonapi object given keys',
                              JSONAPIonify::Structure::Helpers::PaginationLinks,
                              'http://self.me',
                              { self: 'http://self.me' }

        context 'invalid key' do
          it_should_behave_like 'an invalid jsonapi object', foo: 'http://self.me'
        end
      end
    end
  end
end
