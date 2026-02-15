package com.assetinfo.playasset.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "external.providers")
public class ExternalProviderProperties {
    private Provider market = new Provider();
    private Provider news = new Provider();

    @Getter
    @Setter
    public static class Provider {
        private String baseUrl = "";
        private String apiKey = "";
    }
}
