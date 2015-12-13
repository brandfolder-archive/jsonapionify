require 'pry' rescue nil
require 'core_ext/boolean_object'
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"
require 'active_support/cache'
require 'jsonapionify/autoload'

module JSONAPIonify
  autoload :VERSION, 'jsonapi-objects/version'
  extend JSONAPIonify::Autoload
  autoload_all

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
    @cache_store ||= ActiveSupport::Cache.lookup_store :null_store
  end
end
