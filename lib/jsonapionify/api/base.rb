require 'active_support/descendants_tracker'
require 'active_support/core_ext/module/delegation'

module JSONAPIonify::Api
  class Base
    extend JSONAPIonify::Autoload
    autoload_all
    extend AppBuilder
    extend DocHelper
    extend ClassMethods
    extend Delegation
    extend ResourceDefinitions

  end
end
