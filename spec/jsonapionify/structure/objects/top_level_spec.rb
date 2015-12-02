require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Top Level
  # =========
  describe TopLevel do
    include JSONAPIObjects

    schema =
      {
        data:     nil,
        errors:   [],
        meta:     nil,
        links:    {},
        included: [],
        jsonapi:  {}
      }

    # A JSON object **MUST** be at the root of every JSON API request and response
    # containing data. This object defines a document's "top level".
    #
    # A document **MUST** contain at least one of the following top-level members:
    #
    # * `data`: the document's "primary data"
    # * `errors`: an array of [error objects](#errors)
    # * `meta`: a [meta object][meta] that contains non-standard meta-information.
    describe 'must contain one of: data, errors, meta' do
      %i{data errors meta}.each do |key|
        context "when containing `#{key}`" do
          it_should_behave_like 'a valid jsonapi object', key => schema[key]
        end
      end

      context 'when not containing any' do
        it_should_behave_like 'an invalid jsonapi object', {}
      end
    end

    # The members `data` and `errors` **MUST NOT** coexist in the same document.
    describe '`data` and `errors` must not coexist' do
      context 'when both exist' do
        it_should_behave_like 'an invalid jsonapi object', errors: [], data: nil
      end

      %i{data errors}.each do |key|
        context "when only `#{key}` exists" do
          it_should_behave_like 'a valid jsonapi object', key => schema[key]
        end
      end
    end

    # A document **MAY** contain any of these top-level members:
    #
    # * `jsonapi`: an object describing the server's implementation
    # * `links`: a [links object][links] related to the primary data.
    # * `included`: an array of [resource objects] that are related to the primary
    #   data and/or each other ("included resources").
    describe "may contain" do
      keys = %i{jsonapi links included}
      it_should_behave_like 'valid jsonapi object given schema', schema.slice(*keys), data: nil

      context 'when not containing any' do
        it_should_behave_like 'a valid jsonapi object', data: nil
      end
    end

    # If a document does not contain a top-level `data` key, the `included` member
    # **MUST NOT** be present either.

    describe 'cannot contain `included` unless `data` is present' do
      context 'when data is provided' do
        it_should_behave_like 'a valid jsonapi object', data: [], included: []
      end

      context 'when data is not provided' do
        it_should_behave_like 'an invalid jsonapi object', meta: {}, included: []
      end
    end

    # The document's "primary data" is a representation of the resource or collection
    # of resources targeted by a request.
    #
    # Primary data **MUST** be either:
    #
    # * a single ResourceObject, a single ResourceIdentifierObject, or `null`,
    #   for requests that target single resources
    # * an array of ResourceObjects a.k.a. a ResourcesCollection, an array of
    #   ResourceIdentifierObject a.k.a. ResourceIdentifiersCollection, or
    #   an empty Array (`[]`), for requests that target resource collections
    #
    # A logical collection of resources **MUST** be represented as an array, even if
    # it only contains one item or is empty.
    describe 'primary data representation' do

      context 'when a single resource object' do
        obj  = { id: "1", type: 'stuff', attributes: { name: 'hello' } }
        hash = { data: obj }

        it_should_behave_like 'a valid jsonapi object', **hash

        it 'should be a resource object' do
          expect(described_class.new(hash)[:data]).to be_a Resource
        end
      end

      context 'when a single resource identifier object' do
        obj  = { id: "1", type: 'stuff' }
        hash = { data: obj }

        it_should_behave_like 'a valid jsonapi object', **hash

        it 'should be a resource identifier object' do
          $pry = true
          expect(described_class.new(hash)[:data]).to be_a ResourceIdentifier
        end
      end

      context 'when a collection of resource objects' do
        ary  = 3.times.map do |i|
          { id: (i + 1).to_s, type: 'stuff', attributes: { name: 'hello' } }
        end
        hash = { data: ary }

        it_should_behave_like 'a valid jsonapi object', **hash

        it 'should be a collection of resource objects' do
          described_class.new(hash)[:data].each do |obj|
            expect(obj).to be_a Resource
          end
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
    end

    describe 'error collection' do
      let(:object) do
        described_class.new(
          data: [
                  { id: "1" },
                  { id: "1", type: "stuff" }
                ],
          links: {
            foo: "foo",
            self: "bar"
          }
        )
      end
      it 'should collect errors into an error object' do
        expect(object.compile['errors']).to(
          include(
            {
              source: {
                pointer: 'data/0/type'
              },
              detail: 'type must be provided.',
              status: '422'
            }.as_json,
            {
              source: {
                pointer: 'links/foo'
              },
              detail: 'foo is not permitted.',
              status: '422'
            }.as_json,
            {
              source: {
                pointer: 'links/self'
              },
              detail: 'self must be url string or valid link object.',
              status: '422'
            }.as_json
          )
        )
      end
      it 'should only include errors if compile errors exist' do
        expect(object.compile.keys).to eq ['errors']
      end
    end
  end
end
