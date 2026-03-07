# Redis cache wrapper with TTLs and graceful degradation
class CacheService
  class << self
    def fetch(key, ttl_key = :match_details, &block)
      expires = CACHE_TTLS.fetch(ttl_key, 30.minutes)
      Rails.cache.fetch("kl:#{key}", expires_in: expires, skip_nil: true, &block)
    rescue => e
      Rails.logger.error("[CacheService] Cache error for '#{key}': #{e.message}")
      block.call
    end

    def delete(key)
      Rails.cache.delete("kl:#{key}")
    rescue => e
      Rails.logger.error("[CacheService] Delete error for '#{key}': #{e.message}")
    end

    def clear_tournament!
      # Clear all Kings Lendas cache keys
      Rails.cache.delete_matched("kl:*")
    rescue => e
      Rails.logger.error("[CacheService] Clear error: #{e.message}")
    end

    # Fetch with stale-while-revalidate: return stale data if API fails
    def fetch_with_fallback(key, ttl_key = :match_details, &block)
      result = Rails.cache.fetch("kl:#{key}", expires_in: CACHE_TTLS.fetch(ttl_key, 30.minutes), &block)
      { data: result, stale: false }
    rescue => e
      Rails.logger.error("[CacheService] Fallback for '#{key}': #{e.message}")
      stale_data = Rails.cache.read("kl:#{key}")
      { data: stale_data || [], stale: true }
    end
  end
end
