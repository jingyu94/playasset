package com.assetinfo.playasset.batch.external;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.assetinfo.playasset.batch.provider.MarketDataProvider;
import com.assetinfo.playasset.batch.provider.SymbolCatalogProvider;
import com.assetinfo.playasset.config.ExternalProviderProperties;
import com.fasterxml.jackson.databind.JsonNode;

@Component
public class MarketQuoteClient implements MarketDataProvider, SymbolCatalogProvider {

    private static final Logger log = LoggerFactory.getLogger(MarketQuoteClient.class);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(6);

    private final ExternalProviderProperties providerProperties;

    public MarketQuoteClient(ExternalProviderProperties providerProperties) {
        this.providerProperties = providerProperties;
    }

    @Override
    public Map<String, QuoteSnapshot> fetchQuotes(List<String> symbols) {
        if (symbols == null || symbols.isEmpty()) {
            return Collections.emptyMap();
        }

        String apiKey = providerProperties.getMarket().getApiKey();
        String baseUrl = providerProperties.getMarket().getBaseUrl();
        if (apiKey == null || apiKey.isBlank() || baseUrl == null || baseUrl.isBlank()) {
            return Collections.emptyMap();
        }

        String symbolQuery = symbols.stream()
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .distinct()
                .collect(Collectors.joining(","));
        if (symbolQuery.isBlank()) {
            return Collections.emptyMap();
        }

        try {
            JsonNode response = WebClient.builder()
                    .baseUrl(baseUrl)
                    .build()
                    .get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/quote")
                            .queryParam("symbol", symbolQuery)
                            .queryParam("apikey", apiKey)
                            .build())
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block(REQUEST_TIMEOUT);

            if (response == null) {
                return Collections.emptyMap();
            }
            if (response.hasNonNull("status")
                    && "error".equalsIgnoreCase(response.path("status").asText())) {
                log.debug("market quote error for {}: {}", symbolQuery, response.path("message").asText());
                return Collections.emptyMap();
            }

            Map<String, QuoteSnapshot> result = new HashMap<>();
            if (isQuoteNode(response)) {
                parseSnapshot(response).ifPresent(snapshot -> result.put(symbols.get(0), snapshot));
                return result;
            }

            response.fields().forEachRemaining(entry -> {
                JsonNode node = entry.getValue();
                if (node != null && node.isObject()) {
                    parseSnapshot(node).ifPresent(snapshot -> result.put(entry.getKey(), snapshot));
                }
            });
            return result;
        } catch (Exception ex) {
            log.debug("market quote fetch failed for {}: {}", symbolQuery, ex.getMessage());
            return Collections.emptyMap();
        }
    }

    @Override
    public List<SymbolCatalogItem> fetchUsSymbols(int maxCount) {
        if (maxCount <= 0) {
            return List.of();
        }
        String apiKey = providerProperties.getMarket().getApiKey();
        String baseUrl = providerProperties.getMarket().getBaseUrl();
        if (apiKey == null || apiKey.isBlank() || baseUrl == null || baseUrl.isBlank()) {
            return List.of();
        }
        try {
            JsonNode response = WebClient.builder()
                    .baseUrl(baseUrl)
                    .build()
                    .get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/stocks")
                            .queryParam("country", "United States")
                            .queryParam("exchange", "NASDAQ,NYSE,AMEX")
                            .queryParam("apikey", apiKey)
                            .build())
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block(REQUEST_TIMEOUT);

            if (response == null || !response.has("data") || !response.path("data").isArray()) {
                return List.of();
            }
            List<SymbolCatalogItem> items = new java.util.ArrayList<>();
            for (JsonNode node : response.path("data")) {
                String symbol = node.path("symbol").asText("").trim();
                if (symbol.isBlank()) {
                    continue;
                }
                String assetName = node.path("name").asText(symbol).trim();
                if (assetName.isBlank()) {
                    assetName = symbol;
                }
                String exchange = node.path("exchange").asText("US").trim();
                String market = normalizeMarket(exchange);
                String currency = node.path("currency").asText("USD").trim();
                if (currency.isBlank()) {
                    currency = "USD";
                }
                items.add(new SymbolCatalogItem(symbol, assetName, market, currency.toUpperCase()));
                if (items.size() >= maxCount) {
                    break;
                }
            }
            return items;
        } catch (Exception ex) {
            log.debug("symbol catalog fetch failed: {}", ex.getMessage());
            return List.of();
        }
    }

    @Override
    public String providerKey() {
        return "TWELVE_DATA";
    }

    @Override
    public boolean supports(String market, String symbol, String currency) {
        if (symbol == null || symbol.isBlank()) {
            return false;
        }
        boolean usdAsset = currency != null && "USD".equalsIgnoreCase(currency);
        boolean usMarket = market != null && market.toUpperCase().startsWith("US");
        boolean numericKoreanTicker = symbol.matches("\\d{6}");
        return (usdAsset || usMarket) && !numericKoreanTicker;
    }

    private boolean isQuoteNode(JsonNode node) {
        return node.has("close") || node.has("price");
    }

    private Optional<QuoteSnapshot> parseSnapshot(JsonNode node) {
        BigDecimal close = parseDecimal(node, "close")
                .or(() -> parseDecimal(node, "price"))
                .orElse(null);
        if (close == null) {
            return Optional.empty();
        }
        BigDecimal open = parseDecimal(node, "open").orElse(close);
        BigDecimal high = parseDecimal(node, "high").orElse(open.max(close));
        BigDecimal low = parseDecimal(node, "low").orElse(open.min(close));
        BigDecimal volume = parseDecimal(node, "volume").orElse(BigDecimal.valueOf(100000));
        return Optional.of(new QuoteSnapshot(open, high, low, close, volume));
    }

    private String normalizeMarket(String exchange) {
        String normalized = exchange.toUpperCase();
        if (normalized.contains("NASDAQ")) {
            return "US_NASDAQ";
        }
        if (normalized.contains("NYSE")) {
            return "US_NYSE";
        }
        if (normalized.contains("AMEX")) {
            return "US_AMEX";
        }
        return "US";
    }

    private Optional<BigDecimal> parseDecimal(JsonNode node, String fieldName) {
        if (!node.hasNonNull(fieldName)) {
            return Optional.empty();
        }
        try {
            return Optional.of(new BigDecimal(node.path(fieldName).asText()));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }
}
