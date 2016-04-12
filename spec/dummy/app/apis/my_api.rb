require_relative '../../lib/models'
class MyApi < JSONAPIonify::Api::Base
  title "My Awesome API"
  cache :memory_store

  link 'Website', 'http://example.org'

  documentation_order(
    %i{
      things
    }
  )

  before :list do |context|
    # Before actions here
  end

  enable_pagination
end
