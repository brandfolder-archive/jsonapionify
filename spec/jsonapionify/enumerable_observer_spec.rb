require 'spec_helper'
module JSONAPIonify
  describe EnumerableObserver do
    let(:array){ Array.new }
    let(:caller){ Object.new }

    describe 'items added' do
      it 'should observe items added' do
        items_to_add = [1, 2, 3]
        expect(caller).to receive(:items_added).with(items_to_add)
        EnumerableObserver.observe(array).added do |items|
          caller.items_added(items)
        end
        array.concat(items_to_add)
      end
    end

    describe 'items removed' do
      it 'should observe items removed' do
        items_to_remove = [1, 2, 3]
        array.concat(items_to_remove)
        expect(caller).to receive(:items_removed).with(items_to_remove)
        EnumerableObserver.observe(array).removed do |items|
          caller.items_removed(items)
        end
        array.delete_if { |i| items_to_remove.include? i }
      end
    end

    describe 'unobserve' do
      it 'should observe items removed' do
        items_to_remove = [1, 2, 3]
        array.concat(items_to_remove)
        expect(caller).to_not receive(:items_removed)
        EnumerableObserver.observe(array).removed do |items|
          caller.items_removed(items)
        end
        array.observers.first.unobserve
        array.delete_if { |i| items_to_remove.include? i }
      end
    end
  end
end
