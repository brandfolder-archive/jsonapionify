require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Resource Identifier Objects
  # ===========================
  describe ResourceIdentifier do
    include_context 'resource identification'
    # A "resource identifier object" is an object that identifies an individual
    # resource.
    #
    # A "resource identifier object" **MUST** contain `type` and `id` members.
    describe 'must contain an `id` member and a `type` member' do
      context 'when `id` and `type` are provided' do
        data = { id: "1", type: "stuff" }
        it_should_behave_like 'a valid jsonapi object', data
      end

      context 'when only `id` is provided' do
        data = { id: "1" }
        it_should_behave_like 'an invalid jsonapi object', data
      end

      context 'when only `type` is provided' do
        data = { type: "stuff" }
        it_should_behave_like 'an invalid jsonapi object', data
      end

      context 'when `id` and `type` are not provided' do
        data = {}
        it_should_behave_like 'an invalid jsonapi object', data
      end
    end

    # A "resource identifier object" **MAY** also include a `meta` member, whose value is a meta object that
    # contains non-standard meta-information.
    describe 'may contain' do
      schema = {
        meta: {}
      }
      it_should_behave_like 'valid jsonapi object given schema', schema, { id: "1", type: "stuff" }
    end

    describe '#same?' do
      pending
    end

    describe '#duplicate_does_not_exist?' do
      context 'given duplicate identifiers' do
        it 'should not compile' do
          data = {
            data: [
                    { type: 'a', id: '1' },
                    { type: 'a', id: '1' }
                  ]
          }
          expect {
            JSONAPIonify::Structure::Objects::TopLevel.new(data).compile!
          }.to(
            raise_error JSONAPIonify::Structure::ValidationError
          )
        end
      end
    end
  end
end
