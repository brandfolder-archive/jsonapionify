require 'spec_helper'
module JSONAPIonify::Structure::Collections
  describe Errors do
    it 'should force new objects into the right value' do
      expect(described_class.new([{}, {}])).to all be_a JSONAPIonify::Structure::Objects::Error
    end
  end
end
