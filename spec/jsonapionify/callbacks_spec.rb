require 'spec_helper'

module JSONAPIonify
  describe Callbacks do
    let(:klass) do
      Class.new do
        include JSONAPIonify::Callbacks
        define_callbacks :default

        def value_with_callbacks
          run_callbacks :default do
            value
          end
        end

        def value
          @value ||= SecureRandom.hex
        end
      end
    end

    let(:instance) {
      klass.new
    }

    describe '#before_callback' do
      it 'should run the callbacks in order' do
        first_called  = false
        second_called = false
        third_called  = false

        klass.before_default do
          first_called = true
        end

        klass.before_default do
          second_called = first_called == true
        end

        klass.before_default do
          third_called = second_called == true
        end

        expect(instance).to receive(:value).twice.and_call_original
        expect(instance.value_with_callbacks).to eq instance.value
        expect(third_called).to eq true
      end

      it 'should halt if the callbacks fail' do
        first_called  = false
        second_called = false
        third_called  = false

        klass.before_default do
          first_called = true
        end

        klass.before_default do
          second_called = first_called == true
          false
        end

        klass.before_default do
          third_called = true
        end

        expect(instance).to_not receive(:value)
        expect(instance.value_with_callbacks).to eq false
        expect(first_called).to eq true
        expect(second_called).to eq true
        expect(third_called).to eq false
      end

      it 'should pass arguments' do
        out_v = nil
        klass.before_default do |v|
          out_v = v
        end

        expect(instance.run_callbacks(:default, "hello"){ "goodbye" }).to eq "goodbye"
        expect(out_v).to eq "hello"
      end
    end

    describe '#after_callback' do
      it 'should run the callbacks in order' do
        first_called  = false
        second_called = false
        third_called  = false

        klass.after_default do
          first_called = true
        end

        klass.after_default do
          second_called = first_called == true
        end

        klass.after_default do
          third_called = second_called == true
        end

        expect(instance).to receive(:value).twice.and_call_original
        expect(instance.value_with_callbacks).to eq instance.value
        expect(third_called).to eq true
      end

      it 'should halt if the callbacks fail' do
        first_called  = false
        second_called = false
        third_called  = false

        klass.after_default do
          first_called = true
        end

        klass.after_default do
          second_called = first_called == true
          false
        end

        klass.after_default do
          third_called = true
        end

        expect(instance).to receive(:value)
        expect(instance.value_with_callbacks).to eq false
        expect(first_called).to eq true
        expect(second_called).to eq true
        expect(third_called).to eq false
      end
    end
  end
end
