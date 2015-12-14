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

    def self.inherited(subclass)
      super(subclass)
      file           = caller.reject { |f| f.start_with? JSONAPIonify.path }[0].split(/\:\d/)[0]
      dir            = File.expand_path File.dirname(file)
      basename       = File.basename(file, File.extname(file))
      self.load_path = File.join(dir, basename)
      subclass.const_set(:ResourceBase, Class.new(Resource).set_api(subclass))
      load_resources
    end

  end
end
