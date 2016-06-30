module JSONAPIonify::Api
  module Resource::Defaults::Params
    extend ActiveSupport::Concern

    included do
      # Configure the default sort
      default_sort 'id'
    end
  end
end
