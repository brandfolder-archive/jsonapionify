shared_context 'resource identification' do
  include JSONAPIObjects

  # Identification
  # ==============
  describe 'identification' do
    # Every ResourceObject **MUST** contain an `id` member and a `type` member.
    describe '**MUST** contain an `id` member and a `type` member' do
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

    # The values of the `id` and `type` members **MUST** be strings.
    describe 'The values of the `id` and `type` members **MUST** be strings.' do
      context 'when `id` is a string' do
        data = { id: "1", type: "stuff" }
        it_should_behave_like 'a valid jsonapi object', data
      end

      context 'when `id` is not a string' do
        data = { id: nil, type: "stuff" }
        it_should_behave_like 'an invalid jsonapi object', data
      end

      context 'when `type` is a string' do
        data = { id: "1", type: "stuff" }
        it_should_behave_like 'a valid jsonapi object', data
      end

      context 'when `type` is not a string' do
        data = { id: "1", type: nil }
        it_should_behave_like 'an invalid jsonapi object', data
      end

      context 'when both `id` and `type` are strings' do
        data = { id: "1", type: "stuff" }
        it_should_behave_like 'a valid jsonapi object', data
      end

      context 'when both `id` and `type` are not strings' do
        data = { id: nil, type: nil }
        it_should_behave_like 'an invalid jsonapi object', data
      end
    end

    # Within a given API, each resource object's `type` and `id` pair **MUST**
    # identify a single, unique resource. (The set of URIs controlled by a server,
    # or multiple servers acting as one, constitute an API.)
    describe 'unique resources' do

      context 'when all of the resources are unique' do
        parent = JSONAPIonify::Structure::Objects::TopLevel.new(
          data:
            [
              described_class.new(id: "1", "type": "stuff"),
              described_class.new(id: "2", "type": "stuff"),
            ]
        )
        it 'should not be a valid jsonapi object' do
          parent[:data].each do |resource|
            expect { resource.compile! }.to_not raise_error
          end
        end
      end


      context 'when all of the resources are not unique' do
        parent = JSONAPIonify::Structure::Objects::TopLevel.new(
          data:
            [
              described_class.new(id: "1", "type": "stuff"),
              described_class.new(id: "1", "type": "stuff"),
            ]
        )
        it 'should not be a valid jsonapi object' do
          parent[:data].each do |resource|
            expect { resource.compile! }.to raise_error JSONAPIonify::Structure::ValidationError
          end
        end
      end
    end

    # The `type` member is used to describe [resource objects] that share common
    # attributes and relationships.
    #
    # The values of `type` members **MUST** adhere to the same constraints as
    # [member names].
    describe 'type must be a valid member name' do
      context 'when a proper member name' do
        data = { id: "1", type: "valid-name" }
        it_should_behave_like 'a valid jsonapi object', data
      end

      context 'when an improper member name' do
        data = { id: "1", type: "_an-valid-name" }
        it_should_behave_like 'an invalid jsonapi object', data
      end
    end

    # > Note: This spec is agnostic about inflection rules, so the value of `type`
    # can be either plural or singular. However, the same value should be used
    # consistently throughout an implementation.
  end
end
