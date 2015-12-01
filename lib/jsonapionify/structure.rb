module JSONAPIonify
  module Structure

    module Collections
      Dir.glob("#{__dir__}/structure/collections/*.rb").each do |file|
        basename = File.basename file, File.extname(file)
        fullpath = File.expand_path file
        autoload basename.camelize.to_sym, fullpath
      end
    end

    module Maps
      Dir.glob("#{__dir__}/structure/maps/*.rb").each do |file|
        basename = File.basename file, File.extname(file)
        fullpath = File.expand_path file
        autoload basename.camelize.to_sym, fullpath
      end
    end

    module Objects
      include Maps
      Dir.glob("#{__dir__}/structure/objects/*.rb").each do |file|
        basename = File.basename file, File.extname(file)
        fullpath = File.expand_path file
        autoload basename.camelize.to_sym, fullpath
      end
    end

    module Helpers
      Dir.glob("#{__dir__}/structure/helpers/*.rb").each do |file|
        basename = File.basename file, File.extname(file)
        fullpath = File.expand_path file
        autoload basename.camelize.to_sym, fullpath
      end
    end
  end
end
