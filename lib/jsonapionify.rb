require 'pry' rescue nil
require 'core_ext/boolean_object'
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"
require 'active_support/cache'

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

  def self.new_object
    Structure::Objects::TopLevel.new
  end

  def self.cache(store, *args)
    self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
  end

  def self.cache_store=(store)
    @cache_store = store
  end

  def self.cache_store
    @cache_store ||= ActiveSupport::Cache.lookup_store :file_store, 'tmp/jsonapionify/object-cache'
  end
end
