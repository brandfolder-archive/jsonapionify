require 'active_support/inflections'

module JSONAPIonify
  module Autoload
    def self.eager_load!
      load_tracker = {}
      while unloaded.present?
        unloaded.each do |mod, consts|
          consts.each do |const|
            tracker = [mod.name, const].join('::')
            begin
              mod.const_get(const, false)
            rescue NameError => e
              load_tracker[tracker] = load_tracker[tracker].to_i + 1
              if !e.message.include?('uninitialized constant') || load_tracker[tracker] > 10
                raise e
              end
            end
          end
        end
      end
    end

    def self.unloaded
      modules = ObjectSpace.each_object.select do |o|
        o.is_a?(Module)
      end
      modules.each_with_object({}) do |mod, hash|
        autoloadable_constants = mod.constants.each_with_object([]) do |const, ary|
          if mod.autoload?(const) && mod.autoload?(const).include?(__dir__)
            ary << const
          end
        end
        hash[mod]              = autoloadable_constants if autoloadable_constants.present?
      end
    end

    def autoload_all(dir=nil)
      file     = caller[0].split(/\:\d/)[0]
      base_dir = File.expand_path File.dirname(file)
      dir      ||= name.split('::').last.camelize
      Dir.glob("#{base_dir}/#{dir}/*.rb").each do |file|
        basename   = File.basename file, File.extname(file)
        fullpath   = File.expand_path file
        const_name = basename.camelize.to_sym
        autoload const_name, fullpath
      end
    end
  end
end
