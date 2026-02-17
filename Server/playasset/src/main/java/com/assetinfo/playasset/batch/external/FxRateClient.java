package com.assetinfo.playasset.batch.external;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.assetinfo.playasset.batch.provider.FxRateProvider;
import com.assetinfo.playasset.config.ExternalProviderProperties;
import com.fasterxml.jackson.databind.JsonNode;

@Component
public class FxRateClient implements FxRateProvider {

    private static final Logger log = LoggerFactory.getLogger(FxRateClient.class);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(6);

    private final ExternalProviderProperties providerProperties;

    public FxRateClient(ExternalProviderProperties providerProperties) {
        this.providerProperties = providerProperties;
    }

    @Override
    public Optional<BigDecimal> fetchUsdKrw() {
        String baseUrl = providerProperties.getFx().getBaseUrl();
        if (baseUrl == null || baseUrl.isBlank()) {
            return Optional.empty();
        }
        Optional<BigDecimal> primary = fetchRate(baseUrl, "/v1/latest");
        if (primary.isPresent()) {
            return primary;
        }
        return fetchRate(baseUrl, "/latest");
    }

    private Optional<BigDecimal> fetchRate(String baseUrl, String path) {
        try {
            JsonNode response = WebClient.builder()
                    .baseUrl(baseUrl)
                    .build()
                    .get()
                    .uri(uriBuilder -> uriBuilder
                            .path(path)
                            .queryParam("base", "USD")
                            .queryParam("symbols", "KRW")
                            .build())
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block(REQUEST_TIMEOUT);

            if (response == null || !response.has("rates")) {
                return Optional.empty();
            }
            JsonNode rateNode = response.path("rates").path("KRW");
            if (rateNode.isMissingNode() || rateNode.isNull()) {
                return Optional.empty();
            }
            return Optional.of(new BigDecimal(rateNode.asText()));
        } catch (Exception ex) {
            log.debug("fx rate fetch failed for {}: {}", path, ex.getMessage());
            return Optional.empty();
        }
    }

    @Override
    public String providerKey() {
        return "FRANKFURTER";
    }
}
