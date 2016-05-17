require 'spec_helper'

module JSONAPIonify
  describe Callbacks do
    let(:klass) do
      Class.new do
        include JSONAPIonify::Callbacks
        define_callbacks :default
      end
    end


    describe 'failing chain' do
      it 'should not continue' do
        klass.before_default do
          false
        end
        expect(klass.new.run_callbacks(:default) { "FOO" }).to_not eq "FOO"
      end
    end

    it 'should return the value of the block' do
      before_value = false
      in_value     = false
      after_value  = false

      klass.after_default do
        after_value = before_value && in_value
      end

      klass.before_default do
        before_value = true
      end

      value = klass.new.run_callbacks(:default) do
        in_value = before_value
        "FOO"
      end

      expect(after_value).to be_truthy
      expect(value).to eq "FOO"
    end

  end
end
