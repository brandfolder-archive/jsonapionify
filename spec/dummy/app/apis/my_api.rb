require_relative '../../lib/models'
class MyApi < JSONAPIonify::Api::Base
  title "My Awesome API"
  cache :memory_store

  rescue_from ActiveRecord::RecordNotFound, error: :not_found

  documentation_order(
    %i{
      things
    }
  )

  before :index do |context|
    # Before actions here
  end

  pagination do |collection, params, links|
    page_number = Integer(params['number'] || 1)
    page_number = 1 if page_number < 1
    page_size   = Integer(params['size'] || 50)
    raise PaginationError if page_size > 250
    first_page = 1
    last_page  = (collection.count / page_size).ceil
    last_page  = 1 if last_page == 0

    links.first number: 1 unless page_number == first_page
    links.last number: last_page unless page_number == last_page
    links.prev number: page_number - 1 unless page_number <= first_page
    links.next number: page_number + 1 unless page_number >= last_page

    slice_start = (page_number - 1) * page_size
    collection.limit(page_size).offset(slice_start)
  end
end
