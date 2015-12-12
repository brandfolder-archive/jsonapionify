module JSONAPIonify::Api
  module Resource::DefaultActions
    extend ActiveSupport::Concern
    included do
      before(:create) { |context| context.instance = context.new_instance }
      index
      create
      read
      update
      delete
    end
  end
end
