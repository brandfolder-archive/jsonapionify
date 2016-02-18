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

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.descendants.each(&:delete_all)
    users = 5.times.map do
      User.new(
        first_name: Faker::Name.first_name,
        last_name:  Faker::Name.last_name,
        email:      Faker::Internet.email,
        password:   Faker::Internet.password
      )
    end
    User.import users
    things = User.all.each_with_object([]) do |user, ary|
      new_things = 3.times.map do
        user.things.new(
          name:  Faker::Commerce.product_name,
          color: Faker::Commerce.color,
        )
      end
      ary.concat new_things
    end
    Thing.import things
  end
end
