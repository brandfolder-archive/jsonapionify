require 'pry'
require 'core_ext/boolean_object'
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"

module JSONAPIonify
  autoload :VERSION, 'jsonapi-objects/version'

  Dir.glob("#{__dir__}/jsonapionify/*.rb").each do |file|
    basename = File.basename file, File.extname(file)
    fullpath = File.expand_path file
    autoload basename.camelize.to_sym, fullpath
  end

  def self.parse(hash)
    hash = JSON.parse(hash) if hash.is_a? String
    Structure::Objects::TopLevel.from_hash(hash)
  end
end
