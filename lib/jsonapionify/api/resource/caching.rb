module JSONAPIonify::Api
  module Resource::Caching

    def cache_options
      @cache_options ||= {}
    end

    def cache key, **options
      raise Errors::DoubleCacheError, "Cache was already called for this action" if @cache_called
      @cache_called = true
      cache_options.merge! options

      # Build the cache key, and obscure it.
      @__context.meta[:cache_key] = cache_options[:key] = cache_key(
        path:   @__context.request.path,
        accept: @__context.request.accept,
        params: @__context.params,
        key:    key
      )
      # If the cache exists, then fail to cache miss
      if self.class.cache_store.exist?(cache_options[:key]) && !@__context.invalidate_cache?
        raise Errors::CacheHit, cache_options[:key]
      end
    end

    def cache_key(**options)
      self.class.cache_key(**options, action_name: @__context.action_name)
    end

    private

    def __call
      response = super
    rescue Errors::CacheHit
      JSONAPIonify.logger.debug "Cache Hit: #{cache_options[:key]}"
      response = self.class.cache_store.read cache_options[:key]
    ensure
      self.class.cache_store.delete cache_options[:key] unless !response || response[0] < 300
    end

    def __respond(**options)
      super.tap do |status, headers, body|
        if response_definition.cacheable && cache_options.present?
          JSONAPIonify.logger.info "Cache Miss: #{cache_options[:key]}"
          self.class.cache_store.write(
            cache_options[:key],
            [status, headers, body.body],
            **cache_options.except(:key)
          )
        end
      end
    end
  end
end
