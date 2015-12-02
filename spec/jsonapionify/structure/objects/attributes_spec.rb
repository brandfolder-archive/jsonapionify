require 'spec_helper'
module JSONAPIonify::Structure::Objects
  # Attributes
  # ==========
  describe Attributes do
    include JSONAPIObjects
    include_context 'fields object'

    # The value of the `attributes` key **MUST** be an object (an "attributes
    # object"). Members of the attributes object ("attributes") represent information
    # about the [resource object][resource objects] in which it's defined.
    #
    # Attributes may contain any valid JSON value.
    describe "when valid json" do
      data = { first_name: "jason", last_name: "smith", age: 41 }
      it_should_behave_like 'a valid jsonapi object', data
    end

    # Complex data structures involving JSON objects and arrays are allowed as
    # attribute values. However, any object that constitutes or is contained in an
    # attribute **MUST NOT** contain a `relationships` or `links` member, as those
    # members are reserved by this specification for future use.
    describe 'must not contain `relationships` or `links`' do
      it_should_behave_like 'invalid jsonapi object given keys', %i{relationships links}
    end

    # Although has-one foreign keys (e.g. `author_id`) are often stored internally
    # alongside other information to be represented in a resource object, these keys
    # **SHOULD NOT** appear as attributes.
    describe 'foreign keys should not appear in attributes' do
      let(:data) do
        { foo_id: 17 }
      end
      it 'should warn the developer' do
        attributes_object = Attributes.new(data)
        expect(attributes_object).to receive(:warn)
        attributes_object.compile!
      end
    end

    # > Note: See [fields] and [member names] for more restrictions on this container.
  end
end
