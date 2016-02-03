require 'spec_helper'
module JSONAPIonify::Structure::Collections
  describe Base do
    describe ".value_is" do
      it 'should set any new value added to the array as the referenced class' do
        object_klass = Class.new(JSONAPIonify::Structure::Objects::Base)
        klass        = Class.new(described_class) do
          value_is object_klass
        end
        expect(klass.new([{}, {}])).to all be_a object_klass
      end
    end

    describe '.new' do
      pending
    end

    describe '#<<' do
      pending
    end

    describe '#new' do
      pending
    end

    describe '#errors' do
      pending
    end

    describe '#warnings' do
      pending
    end
  end
end
