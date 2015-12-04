module JSONAPIonify::Api
  Dir.glob("#{__dir__}/api/*.rb").each do |file|
    basename = File.basename file, File.extname(file)
    fullpath = File.expand_path file
    autoload basename.camelize.to_sym, fullpath
  end

  module Actions
    Dir.glob("#{__dir__}/api/actions/*.rb").each do |file|
      basename = File.basename file, File.extname(file)
      fullpath = File.expand_path file
      autoload basename.camelize.to_sym, fullpath
    end
  end
end
