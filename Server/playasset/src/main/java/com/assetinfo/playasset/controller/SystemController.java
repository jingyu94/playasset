package com.assetinfo.playasset.controller;

import java.time.Instant;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.batch.provider.FxRateProvider;
import com.assetinfo.playasset.batch.provider.MarketDataProvider;
import com.assetinfo.playasset.config.ExternalProviderProperties;

import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/controller/system")
public class SystemController {

    private final ExternalProviderProperties providerProperties;
    private final List<MarketDataProvider> marketDataProviders;
    private final FxRateProvider fxRateProvider;

    public SystemController(
            ExternalProviderProperties providerProperties,
            List<MarketDataProvider> marketDataProviders,
            FxRateProvider fxRateProvider) {
        this.providerProperties = providerProperties;
        this.marketDataProviders = marketDataProviders;
        this.fxRateProvider = fxRateProvider;
    }

    @GetMapping("/reactive-probe")
    public Mono<Map<String, Object>> reactiveProbe() {
        return Mono.fromSupplier(() -> {
            Map<String, Object> result = new HashMap<>();
            result.put("mode", "mvc-vt + reactive");
            result.put("timestamp", Instant.now().toString());
            return result;
        });
    }

    @GetMapping("/runtime-profile")
    public Map<String, Object> runtimeProfile() {
        Map<String, Object> result = new HashMap<>();
        result.put("mode", "mvc-vt + reactive");
        result.put("marketApiKeyConfigured", !providerProperties.getMarket().getApiKey().isBlank());
        result.put("newsApiKeyConfigured", !providerProperties.getNews().getApiKey().isBlank());
        result.put("fxBaseUrlConfigured", !providerProperties.getFx().getBaseUrl().isBlank());
        result.put("marketFreeMaxSymbols", providerProperties.getMarket().getFreeMaxSymbols());
        result.put("marketProviders", marketDataProviders.stream().map(MarketDataProvider::providerKey).toList());
        result.put("fxProvider", fxRateProvider.providerKey());
        result.put("timestamp", Instant.now().toString());
        return result;
    }
}
