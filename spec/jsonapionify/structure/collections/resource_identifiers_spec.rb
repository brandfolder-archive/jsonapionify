require 'spec_helper'
module JSONAPIonify::Structure::Collections
  describe ResourceIdentifiers do
    it 'should force new objects into the right value' do
      expect(described_class.new([{}, {}])).to all be_a JSONAPIonify::Structure::Objects::ResourceIdentifier
    end
  end
end
