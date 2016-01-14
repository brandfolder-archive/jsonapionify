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
      subclass.instance_exec(self) do |superclass|
        file           = caller.reject { |f| f.start_with? JSONAPIonify.path }[0].split(/\:\d/)[0]
        dir            = File.expand_path File.dirname(file)
        basename       = File.basename(file, File.extname(file))
        self.load_path = File.join(dir, basename)

        const_set(:ResourceBase, Class.new(superclass.resource_class))
        resource_class.set_api(self)
        load_resources
      end
    end

    def self.resource_class
      if const_defined?(:ResourceBase, false)
        const_get(:ResourceBase, false)
      else
        const_set(:ResourceBase, Class.new(Resource))
      end
    end

  end
end
