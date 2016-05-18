module JSONAPIonify::Api
  module Resource::Caching
    def cache key, **options
      raise Errors::DoubleCacheError, "Cache was already called for this action" if @cache_called
      @cache_called = true
      @cache_options.merge! options

      # Build the cache key, and obscure it.
      @__context.meta[:cache_key] = @cache_options[:key] = cache_key(
        path:   @__context.request.path,
        accept: @__context.request.accept,
        params: @__context.params,
        key:    key
      )
      # If the cache exists, then fail to cache miss
      if self.class.cache_store.exist?(@cache_options[:key]) && !@__context.invalidate_cache?
        raise Errors::CacheHit, @cache_options[:key]
      end
    end

    def cache_key(**options)
      self.class.cache_key(
        **options,
        action_name: action_name
      )
    end
  end
end
