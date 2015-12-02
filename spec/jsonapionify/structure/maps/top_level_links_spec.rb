require 'spec_helper'
module JSONAPIonify::Structure::Maps
  describe TopLevelLinks do
    include JSONAPIObjects
    # The top-level [links object][links] **MAY** contain the following members:
    #
    # * `self`: the [link][links] that generated the current response document.
    # * `related`: a [related resource link] when the primary data represents a
    #    resource relationship.
    # * [pagination] links for the primary data.

    describe "may contain" do
      keys = [*%i{self related}, *JSONAPIonify::Structure::Helpers::PaginationLinks]
      it_should_behave_like 'valid jsonapi object given keys', keys, 'http://self.me'

      context 'when not containing any' do
        it_should_behave_like 'an invalid jsonapi object', data: nil
      end
    end
  end
end
