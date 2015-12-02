require 'spec_helper'
module JSONAPIonify::Structure::Collections
  describe IncludedResources do
    it 'should force new objects into the right value' do
      expect(described_class.new([{}, {}])).to all be_a JSONAPIonify::Structure::Objects::IncludedResource
    end

    describe '.referenceable?' do
      pending
    end

    describe '#referenced' do
      pending
    end
  end
end
