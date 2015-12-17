module JSONAPIonify::Api
  module Resource::Definitions::Pagination

    class PaginationLinksDelegate

      def initialize(request, links)
        @request = request
        @links   = links
      end

      %i{first last next prev}.each do |method|
        define_method method do |**options|
          @links[method] = URI.parse(@request.url).tap do |uri|
            page_params = { page: options }.deep_stringify_keys
            uri.query   = @request.params.deep_merge(page_params).to_param
          end.to_s
        end
      end

    end

    STRATEGIES         = {
      active_record: proc do |collection, params, links|
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
      end,
      enumerable:    proc do |collection, params, links|
        page_number = Integer(params['number'] || 1)
        page_number = 1 if page_number < 1
        page_size   = Integer(params['size'] || 50)
        first_page  = 1
        last_page   = (collection.count / page_size).ceil
        last_page   = 1 if last_page == 0

        links.first number: 1 unless page_number == first_page
        links.last number: last_page unless page_number == last_page
        links.prev number: page_number - 1 unless page_number <= first_page
        links.next number: page_number + 1 unless page_number >= last_page

        slice_start = (page_number - 1) * page_size

        collection.slice(slice_start, page_size)
      end
    }
    STRATEGIES[:array] = STRATEGIES[:enumerable]
    DEFAULT            = STRATEGIES[:enumerable]

    def pagination(*params, strategy: nil, &block)
      params = %i{number size} unless block
      params.each { |p| param :page, p, actions: %i{list} }
      context :paginated_collection do |context|
        unless (actual_block = block)
          actual_strategy = strategy || self.class.default_strategy
          actual_block    = actual_strategy ? STRATEGIES[actual_strategy] : DEFAULT
        end
        Object.new.instance_exec(
          context.respond_to?(:sorted_collection) ? context.sorted_collection : context.collection,
          context.request.params['page'] || {},
          PaginationLinksDelegate.new(context.request, context.links),
          &actual_block
        )
      end
    end

  end
end
