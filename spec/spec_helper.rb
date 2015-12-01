require 'simplecov'
SimpleCov.start do
  add_filter "/spec"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'jsonapionify'

Dir.glob(File.join __dir__, 'shared_contexts/**/*.rb').each { |f| require f }
