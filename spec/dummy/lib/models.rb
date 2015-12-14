require 'activerecord-import'
require 'yaml'
config = YAML.load_file(File.expand_path '../config/database.yml', __dir__)
ActiveRecord::Base.establish_connection config[ENV['RACK_ENV']]
Dir.glob("#{__dir__}/../app/models/**/*.rb").each { |f| require f }
