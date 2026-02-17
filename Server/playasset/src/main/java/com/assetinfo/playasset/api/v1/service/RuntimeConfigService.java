package com.assetinfo.playasset.api.v1.service;

import java.util.Map;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.config.CacheNames;

@Service
public class RuntimeConfigService {

    public static final String GROUP_ADVISOR_RULE = "ADVISOR_RULE";
    public static final String GROUP_ADVISOR_MESSAGE = "ADVISOR_MESSAGE";
    public static final String GROUP_SIMULATION_MESSAGE = "SIMULATION_MESSAGE";
    public static final String GROUP_MARKET_BATCH_MESSAGE = "MARKET_BATCH_MESSAGE";

    private final PlatformQueryRepository repository;

    public RuntimeConfigService(PlatformQueryRepository repository) {
        this.repository = repository;
    }

    @Cacheable(cacheNames = CacheNames.RUNTIME_CONFIG, key = "#groupCode")
    public Map<String, String> loadGroup(String groupCode) {
        return repository.loadRuntimeConfigMap(groupCode);
    }

    public String getString(String groupCode, String key, String defaultValue) {
        String value = loadGroup(groupCode).get(key);
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        return value.trim();
    }

    public int getInt(String groupCode, String key, int defaultValue) {
        String raw = loadGroup(groupCode).get(key);
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    public double getDouble(String groupCode, String key, double defaultValue) {
        String raw = loadGroup(groupCode).get(key);
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }
        try {
            return Double.parseDouble(raw.trim());
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    @CacheEvict(cacheNames = CacheNames.RUNTIME_CONFIG, key = "#groupCode")
    public void evictGroup(String groupCode) {
        // Cache eviction marker method
    }
}
