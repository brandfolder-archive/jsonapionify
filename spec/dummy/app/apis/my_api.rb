require_relative '../../lib/models'
class MyApi < JSONAPIonify::Api::Base
  title "My Awesome API"
  cache :memory_store

  link 'Website', 'http://example.org'

  rescue_from ActiveRecord::RecordNotFound, error: :not_found

  documentation_order(
    %i{
      things
    }
  )

  before :list do |context|
    # Before actions here
  end

  enable_pagination
  enable_sorting
end
