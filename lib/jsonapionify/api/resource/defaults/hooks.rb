module JSONAPIonify::Api
  module Resource::Defaults::Hooks
    extend ActiveSupport::Concern

    included do
      after :commit_update, :commit_create do |instance:|
        if defined?(ActiveRecord) && instance.is_a?(ActiveRecord::Base)
          # Collect Errors
          if instance.errors.present?
            instance.errors.messages.each do |attr, messages|
              messages.each do |message|
                error :invalid_attribute, attr, message
              end
            end
          end
        end
      end
    end

  end
end
