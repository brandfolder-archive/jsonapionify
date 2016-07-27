require 'spec_helper'
module JSONAPIonify::Structure::Objects
  describe Relationship do
    include JSONAPIObjects
    # A "relationship object" **MUST** contain at least one of the following:
    #
    # * `links`: a links object
    # * `data`: resource linkage
    # * `meta`: a meta object that contains non-standard meta-information about the relationship.
    describe 'must contain one of' do
      schema = {
        links: {},
        data:  nil,
        meta:  {}
      }
      schema.each do |key, value|
        data = { key => value }
        it_should_behave_like 'a valid jsonapi object', data
      end
    end
    # > Note: See fields and member names for more restrictions on this container.

    # Resource Linkage
    # ================
    describe 'Resource Linkage' do
      # Resource linkage in a [compound document] allows a client to link together all
      # of the included [resource objects] without having to `GET` any URLs via [links].
      #
      # Resource linkage **MUST** be represented as one of the following:
      #
      # * `null` for empty to-one relationships.
      # * an empty array (`[]`) for empty to-many relationships.
      # * a single [resource identifier object] for non-empty to-one relationships.
      # * an array of [resource identifier objects][resource identifier object] for non-empty to-many relationships.


      context 'when a single resource identifier object' do
        obj  = { id: "1", type: 'stuff' }
        hash = { data: obj }

        it_should_behave_like 'a valid jsonapi object', **hash

        it 'should be a resource identifier object' do
          expect(described_class.new(hash)[:data]).to be_a ResourceIdentifier
        end
      end

      context 'when a collection of resource identifier objects' do
        ary  = 3.times.map do |i|
          { id: (i + 1).to_s, type: 'stuff' }
        end
        hash = { data: ary }

        it_should_behave_like 'a valid jsonapi object', **hash

        it 'should be a collection of resource identifier objects' do
          described_class.new(hash)[:data].each do |obj|
            expect(obj).to be_a ResourceIdentifier
          end
        end
      end

      context 'when an empty array' do
        hash = { data: [] }

        it_should_behave_like 'a valid jsonapi object', **hash
      end

      context 'when null' do
        hash = { data: nil }

        it_should_behave_like 'a valid jsonapi object', **hash
      end

      context 'when something else' do
        hash = { data: 1 }
        it_should_behave_like 'an invalid jsonapi object', **hash
      end

      # > Note: The spec does not impart meaning to order of resource identifier
      # objects in linkage arrays of to-many relationships, although implementations
      # may do that. Arrays of resource identifier objects may represent ordered
      # or unordered relationships, and both types can be mixed in one response
      # object.
    end
  end
end
