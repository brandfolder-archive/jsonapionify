require 'active_support/descendants_tracker'
require 'redcarpet'
require 'active_support/core_ext/module/delegation'

module JSONAPIonify::Api
  class Base
    Dir.glob("#{__dir__}/base/*.rb").each do |file|
      basename = File.basename file, File.extname(file)
      fullpath = File.expand_path file
      autoload basename.camelize.to_sym, fullpath
    end

    extend AppBuilder
    extend DocHelper
    extend ClassMethods
    extend Delegation
    extend ResourceDefinitions

  end
end
