module JSONAPIonify::Api
  module Resource::DefaultActions
    extend ActiveSupport::Concern
    included do
      before(:index) { |context| context.instance = context.new_instance }
      index
      create
      read
      update
      delete
    end
  end
end