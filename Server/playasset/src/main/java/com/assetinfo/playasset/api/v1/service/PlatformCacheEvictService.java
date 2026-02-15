package com.assetinfo.playasset.api.v1.service;

import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.config.CacheNames;

@Service
public class PlatformCacheEvictService {

    private final CacheManager cacheManager;

    public PlatformCacheEvictService(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    public void evictMarketDrivenCaches() {
        clear(CacheNames.DASHBOARD);
        clear(CacheNames.POSITIONS);
        clear(CacheNames.WATCHLIST);
        clear(CacheNames.PORTFOLIO_ADVICE);
        clear(CacheNames.PORTFOLIO_SIMULATION);
    }

    public void evictNewsDrivenCaches() {
        clear(CacheNames.DASHBOARD);
        clear(CacheNames.ALERTS);
        clear(CacheNames.PORTFOLIO_ADVICE);
    }

    public void evictSimulationCaches() {
        clear(CacheNames.PORTFOLIO_SIMULATION);
    }

    private void clear(String cacheName) {
        Cache cache = cacheManager.getCache(cacheName);
        if (cache != null) {
            cache.clear();
        }
    }
}
