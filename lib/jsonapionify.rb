require 'pry' rescue nil
require 'core_ext/boolean'
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"
require 'active_support/cache'
require 'jsonapionify/autoload'
require 'oj'

module JSONAPIonify
  autoload :VERSION, 'jsonapi-objects/version'
  extend JSONAPIonify::Autoload
  autoload_all 'jsonapionify'

  TRUTHY_STRINGS = %w(t true y yes 1).flat_map do |str|
    [str.downcase, str.upcase, str.capitalize]
  end.uniq

  FALSEY_STRINGS = %w(f false n no 0).flat_map do |str|
    [str.downcase, str.upcase, str.capitalize]
  end.uniq

  def self.path
    __dir__
  end

  def self.parse(hash)
    hash = Oj.load(hash) if hash.is_a? String
    Structure::Objects::TopLevel.from_hash(hash)
  end

  def self.new_object(*args)
    Structure::Objects::TopLevel.new(*args)
  end

  def self.cache(store, *args)
    self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
  end

  def self.files
    Dir.glob(File.join __dir__, './**/*.rb').map { |f| File.expand_path f }.sort
  end

  def self.digest
    @digest ||=
      files.map do |f|
        File.read f
      end.reduce(
        Digest::SHA2.new, :update
      ).to_s
  end

  def self.verbose_errors=(value)
    self.show_backtrace = @verbose_errors = value
  end

  def self.verbose_errors
    return @verbose_errors if instance_variable_defined?(:@verbose_errors)
    self.verbose_errors = ENV['RACK_ENV'] != 'production'
  end

  def self.show_backtrace=(value)
    @show_backtrace = value
  end

  def self.show_backtrace
    return @show_backtrace if instance_variable_defined?(:@show_backtrace)
    self.show_backtrace = ENV['RACK_ENV'] != 'production'
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new('/dev/null')
  end

  def self.cache_store=(store)
    @cache_store = store
  end

  def self.disable_validation(bool)
    @validation_disabled = bool
  end

  def self.validation_disabled?
    !!@validation_disabled
  end

  def self.cache_store
    @cache_store ||= ActiveSupport::Cache.lookup_store :null_store
  end
end
