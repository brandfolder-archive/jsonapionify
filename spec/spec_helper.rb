require 'simplecov'
SimpleCov.start do
  add_filter "/spec"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'jsonapionify'
require 'active_support/core_ext/object/json'

Dir.glob(File.join __dir__, 'shared_contexts/**/*.rb').each { |f| require f }
