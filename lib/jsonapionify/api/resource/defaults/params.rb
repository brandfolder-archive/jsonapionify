module JSONAPIonify::Api
  module Resource::Defaults::Params
    extend ActiveSupport::Concern

    included do
      param :'include-relationships'

      # Configure the default sort
      default_sort 'id'
    end
  end
end
