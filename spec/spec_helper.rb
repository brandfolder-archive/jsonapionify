require 'bundler/setup'
require 'active_support/json'
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'jsonapionify'
JSONAPIonify::Autoload.eager_load!
require 'active_support/core_ext/object/json'

Dir.glob(File.join __dir__, 'shared_contexts/**/*.rb').each { |f| require f }

ENV['RACK_ENV'] = 'test'
require 'dummy/config/environment'
require_relative './api_helper'
migrate_dir = File.expand_path('dummy/db/migrate', __dir__)
ActiveRecord::Migrator.migrate(migrate_dir, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
ActiveRecord::Base.descendants.each { |c| c.reset_column_information }
