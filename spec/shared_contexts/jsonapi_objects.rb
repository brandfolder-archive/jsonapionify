require 'active_support/concern'
module JSONAPIObjects
  extend ActiveSupport::Concern
  included do
    let(:origin) { :server }

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
        expect { object.compile! }.to raise_error(JSONAPIonify::Structure::Helpers::ValidationError)
      end
    end
  end

  module ClassMethods
    def keycombos(keys)
      1.upto(keys.length).map { |count| keys.combination(count).to_a }
    end

    def keystohash(keys, default=nil)
      keys.each_with_object({}) { |k, h| h[k] = default }
    end

    def keynames(keys)
      keys.map { |k| "`#{k}`" }.to_sentence
    end
  end
end
