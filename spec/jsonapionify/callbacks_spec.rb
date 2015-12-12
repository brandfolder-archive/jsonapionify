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
        expect(klass.new.run_callbacks(:default){ "FOO" }).to_not eq "FOO"
      end
    end

  end
end
