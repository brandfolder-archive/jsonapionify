require 'active_support/concern'
module JSONAPIObjects
  extend ActiveSupport::Concern
  included do
    let(:origin) { :server }

    def self.keycombos(keys)
      1.upto(keys.length).map { |count| keys.combination(count).to_a }
    end

    def self.keystohash(keys, default=nil)
      keys.each_with_object({}) { |k, h| h[k] = default }
    end

    def self.keynames(keys)
      keys.map { |k| "`#{k}`" }.to_sentence
    end

    shared_examples "a valid jsonapi object" do |data|
      it "should be a valid jsonapi object" do
        object = described_class.new(data)
        allow(object).to receive(:origin).and_return origin
        expect { object.compile! }.to_not raise_error
      end
    end

    shared_examples "an invalid jsonapi object" do |data|
      it "should not be a valid jsonapi object" do
        object = described_class.new(data)
        allow(object).to receive(:origin).and_return origin
        expect { object.compile! }.to raise_error(JSONAPIonify::Structure::ValidationError)
      end
    end

    shared_examples "valid jsonapi object given schema" do |schema, required = {}|
      comboset = keycombos(schema.keys)
      comboset.each do |combos|
        combos.each do |keys|
          context "may contain #{keynames keys}" do
            data = schema.slice(*keys)
            data.merge! required
            it_should_behave_like 'a valid jsonapi object', data
          end
        end
      end
    end

    shared_examples "valid jsonapi object given keys" do |input_keys, default = nil, required = {}|
      keycombos(input_keys).each do |combos|
        combos.each do |keys|
          context "may contain #{keynames keys}" do
            data = keystohash keys, default
            data.merge! required
            it_should_behave_like 'a valid jsonapi object', data
          end
        end
      end
    end

    shared_examples "invalid jsonapi object given keys" do |input_keys|
      keycombos(input_keys).each do |combos|
        combos.each do |keys|
          context "may contain #{keynames keys}" do
            data = keystohash keys
            it_should_behave_like 'an invalid jsonapi object', data
          end
        end
      end
    end
  end
end
