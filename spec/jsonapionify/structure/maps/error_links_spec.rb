require 'spec_helper'
module JSONAPIonify::Structure::Maps
  # Error Links
  # ==============
  describe ErrorLinks do
    include JSONAPIObjects
    # a links object containing the following members:
    # * `about`: a link that leads to further details about this
    #   particular occurrence of the problem.
    describe 'may contain about' do
      context 'with a valid key' do
        it_should_behave_like 'a valid jsonapi object', about: 'http://google.com'
      end

      context 'with an invalid key' do
        it_should_behave_like 'an invalid jsonapi object', foo: 'bar'
      end
    end
  end
end
