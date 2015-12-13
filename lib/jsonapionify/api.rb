module JSONAPIonify::Api
  extend JSONAPIonify::Autoload
  autoload_all

  module Actions
    extend JSONAPIonify::Autoload
    autoload_all 'api/actions'
  end
end
