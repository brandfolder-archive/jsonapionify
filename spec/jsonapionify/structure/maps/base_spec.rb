require 'spec_helper'
module JSONAPIonify::Structure::Maps
  describe Base do
    describe ".value_is" do
      it 'should set any new value added to the array as the referenced class' do
        object_klass = Class.new(JSONAPIonify::Structure::Objects::Base)
        klass        = Class.new(described_class) do
          value_is object_klass
        end
        expect(klass.new({ a: {} }).values).to all be_a object_klass
      end

      context 'strict: true' do
        let(:klass) do
          object_class = Class.new(JSONAPIonify::Structure::Objects::Base)
          Class.new(described_class) do
            value_is object_class, strict: true
          end
        end

        context 'given the value is a hash' do
          it 'should compile' do
            expect { klass.new({ a: {} }).compile! }.to_not raise_error
          end
        end

        context 'given the value is not a hash' do
          it 'should not compile' do
            expect { klass.new({ a: 'b' }).compile! }.to raise_error JSONAPIonify::Structure::ValidationError
          end
        end
      end
    end

    describe '.type!' do
      let(:klass) do
        object_class = Class.new(JSONAPIonify::Structure::Objects::Base)
        Class.new(described_class) do
          value_is object_class
          type! must_be: object_class
        end
      end

      context 'given the value is a hash' do
        it 'should compile' do
          expect { klass.new({ a: {} }).compile! }.to_not raise_error
        end
      end

      context 'given the value is not a hash' do
        it 'should not compile' do
          expect { klass.new({ a: 'b' }).compile! }.to raise_error JSONAPIonify::Structure::ValidationError
        end
      end
    end
  end
end
