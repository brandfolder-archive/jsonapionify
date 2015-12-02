module JSONAPIonify
  module Callbacks
    extend ActiveSupport::Concern
    included do
      include ActiveSupport::Callbacks

      def self.define_callbacks(*names, **options)
        names.each do |name|
          %i{before after around}.each do |placement|
            define_singleton_method "#{placement}_#{name}" do |*args, **opts, &block|
              set_callback name, placement, *args, **opts, &block
            end
          end
        end
        super(*names, **options)
      end
    end
  end
end
