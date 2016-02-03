require 'bundler/setup'
require 'rack'
require 'jsonapionify'
require 'navigable_hash'
require 'json'

api    = NavigableHash.new JSON.load File.read 'fixtures/documentation.json'
docs   = JSONAPIonify::Documentation.new(api)
result = docs.result

run ->(_) {
  response = Rack::Response.new
  response.write result
  response.finish
}
