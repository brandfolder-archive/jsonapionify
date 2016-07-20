require 'active_support/concern'

module JSONAPIonify::Api
  module Resource::Callbacks
    extend ActiveSupport::Concern
    using JSONAPIonify::DestructuredProc
    included do
      include JSONAPIonify::Callbacks

      define_callback_strategy do |*args, &block|
        instance_exec(*args, @__context, &block.destructure)
      end
    end
  end
end
