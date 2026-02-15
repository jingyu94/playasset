package com.assetinfo.playasset.controller;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.config.ExternalProviderProperties;

import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/controller/system")
public class SystemController {

    private final ExternalProviderProperties providerProperties;

    public SystemController(ExternalProviderProperties providerProperties) {
        this.providerProperties = providerProperties;
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
        result.put("timestamp", Instant.now().toString());
        return result;
    }
}
