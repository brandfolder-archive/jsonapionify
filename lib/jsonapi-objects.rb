require 'pry'
require "jsonapi-objects/version"
require "active_support/core_ext/string/inflections"

module JSONAPIObjects
  autoload :VERSION, 'jsonapi-objects/version'
  autoload :JSONAPIObject, 'jsonapi-objects/json_api_object'

  Dir.glob("#{__dir__}/jsonapi-objects/*.rb").each do |file|
    basename = File.basename file, File.extname(file)
    fullpath = File.expand_path file
    autoload basename.camelize.to_sym, fullpath
  end
end
