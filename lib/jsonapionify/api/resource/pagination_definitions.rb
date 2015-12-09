module JSONAPIonify::Api
  module Resource::PaginationDefinitions

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

    def self.extended(klass)
      klass.class_eval do
        pagination do |collection, params, links|
          page_number = Integer(params['number'] || 1)
          page_number = 1 if page_number < 1
          page_size   = Integer(params['size'] || 50)
          first_page  = 1
          last_page   = (collection.count / page_size).ceil

          links.first number: 1
          links.last number: last_page
          links.prev number: page_number - 1 unless page_number <= first_page
          links.next number: page_number + 1 unless page_number >= last_page

          slice_start = (page_number - 1) * page_size

          collection.slice(slice_start, page_size)
        end
      end
    end

    def pagination(&block)
      define_method :paginated_collection do
        block.call(collection, request.params['page'] || {}, PaginationLinksDelegate.new(request, links))
      end
    end

  end
end