module JSONAPIonify::Api
  module Resource::Includer
    extend ActiveSupport::Concern

    included do
      param :include
    end

  end
end
