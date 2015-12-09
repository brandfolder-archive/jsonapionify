ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: 'db/data.sqlite3'
Dir.glob("#{__dir__}/../app/models/**/*.rb").each { |f| require f }
