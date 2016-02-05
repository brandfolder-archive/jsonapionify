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

    def self.extended(klass)
      klass.class_eval do
        inherited_hash_attribute :pagination_strategies

        define_pagination_strategy 'Object' do |collection|
          collection
        end

        define_pagination_strategy 'Enumerable' do |collection, params, links|
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

        define_pagination_strategy 'ActiveRecord::Relation' do |collection, params, links|
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
          collection.limit(page_size).offset(slice_start)
        end
      end
    end

    def define_pagination_strategy(mod, &block)
      pagination_strategies[mod.to_s] = block
    end

    def enable_pagination
      %i{number size}.each { |p| param :page, p, actions: %i{list} }
      context :paginated_collection do |context|
        collection = context.respond_to?(:sorted_collection) ? context.sorted_collection : context.collection
        _, block   = pagination_strategies.to_a.reverse.to_h.find do |mod, _|
          Object.const_defined?(mod, false) && context.collection.class <= Object.const_get(mod, false)
        end

        Object.new.instance_exec(
          collection,
          context.request.params['page'] || {},
          PaginationLinksDelegate.new(context.request, context.links),
          &block
        )
      end
    end

  end
end
