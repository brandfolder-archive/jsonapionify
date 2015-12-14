ENV['BUNDLE_GEMFILE'] = File.expand_path('../../../Gemfile', __dir__)
require 'bundler/setup'
require 'jsonapionify'
require 'active_record'
require 'faker'
require_relative '../app/apis/my_api'

ActiveRecord::Base.logger = Logger.new STDOUT if ENV['RACK_ENV'] == 'development'
