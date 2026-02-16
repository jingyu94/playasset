package com.assetinfo.playasset.config;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisCacheConfig {

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration baseConfig = RedisCacheConfiguration.defaultCacheConfig()
                .disableCachingNullValues()
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair
                        .fromSerializer(new GenericJackson2JsonRedisSerializer()))
                .computePrefixWith(cacheName -> "playasset:" + cacheName + "::")
                .entryTtl(Duration.ofSeconds(120));

        Map<String, RedisCacheConfiguration> cacheConfigs = new HashMap<>();
        cacheConfigs.put(CacheNames.DASHBOARD, baseConfig.entryTtl(Duration.ofSeconds(45)));
        cacheConfigs.put(CacheNames.POSITIONS, baseConfig.entryTtl(Duration.ofSeconds(45)));
        cacheConfigs.put(CacheNames.WATCHLIST, baseConfig.entryTtl(Duration.ofSeconds(90)));
        cacheConfigs.put(CacheNames.ALERTS, baseConfig.entryTtl(Duration.ofSeconds(30)));
        cacheConfigs.put(CacheNames.ALERT_PREFERENCES, baseConfig.entryTtl(Duration.ofMinutes(3)));
        cacheConfigs.put(CacheNames.PORTFOLIO_ADVICE, baseConfig.entryTtl(Duration.ofMinutes(5)));
        cacheConfigs.put(CacheNames.PORTFOLIO_SIMULATION, baseConfig.entryTtl(Duration.ofMinutes(10)));

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(baseConfig)
                .withInitialCacheConfigurations(cacheConfigs)
                .transactionAware()
                .build();
    }
}
