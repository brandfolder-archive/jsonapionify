module JSONAPIonify::Api
  module Resource::Defaults::Params
    extend ActiveSupport::Concern

    included do
      param :'include-relationships'
    end
  end
end
