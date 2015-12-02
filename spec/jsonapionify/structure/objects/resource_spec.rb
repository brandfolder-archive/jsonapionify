require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Resource Objects
  # ================
  describe Resource do
    include JSONAPIObjects
    include_context 'resource identification'
    # "Resource objects" appear in a JSON API document to represent resources.
    #
    # A resource object **MUST** contain at least the following top-level members:
    #
    # * `id`
    # * `type`
    describe 'must contain `id` and `type`' do
      context 'with both keys' do
        it_should_behave_like 'a valid jsonapi object', id: "1", type: "stuff"
      end

      %i{id type}.each do |key|
        context "with only `#{key}`" do
          it_should_behave_like 'an invalid jsonapi object', key => "value"
        end
      end
    end

    # Exception: The `id` member is not required when the resource object originates at
    # the client and represents a new resource to be created on the server.
    describe 'the client does not require id' do
      let(:origin) { :client }

      context 'with both keys' do
        it_should_behave_like 'a valid jsonapi object', id: "1", type: "stuff"
      end

      context 'with only `type`' do
        it_should_behave_like 'a valid jsonapi object', type: "stuff"
      end

      context 'with only `id`' do
        it_should_behave_like 'an invalid jsonapi object', id: "1"
      end
    end

    # In addition, a resource object **MAY** contain any of these top-level members:
    #
    # * `attributes`: an [attributes object][attributes] representing some of the resource's data.
    # * `relationships`: a [relationships object][relationships] describing relationships between
    #  the resource and other JSON API resources.
    # * `links`: a [links object][links] containing links related to the resource.
    # * `meta`: a [meta object][meta] containing non-standard meta-information about a
    #   resource that can not be represented as an attribute or relationship.

    describe "may contain" do
      keys          = %i{attributes relationships links meta}
      required_info = { type: "stuff", id: "1" }
      it_should_behave_like 'valid jsonapi object given keys', keys, {}, required_info

      context 'when not containing any' do
        it_should_behave_like 'a valid jsonapi object', required_info
      end
    end

    # Fields
    # ======
    # A resource object's [attributes] and its [relationships] are collectively called
    # its "[fields]".
    #
    # Fields for a ResourceObjects **MUST** share a common namespace with each
    # other and with `type` and `id`. In other words, a resource can not have an
    # attribute and relationship with the same name
    describe 'must not have an attribute and relationship with the same name' do
      let(:resource) do
        described_class.new(
          type:          "stuff",
          id:            "1",
          attributes:    {
            foo: nil
          },
          relationships: {
            foo: {
              data: {}
            }
          }
        )
      end
      it 'attributes should not be a valid jsonapi object' do
        expect { resource[:attributes].compile! }.to raise_error JSONAPIonify::Structure::Helpers::ValidationError
      end

      it 'relationships should not be a valid jsonapi object' do
        expect { resource[:relationships].compile! }.to raise_error JSONAPIonify::Structure::Helpers::ValidationError
      end
    end
  end
end
