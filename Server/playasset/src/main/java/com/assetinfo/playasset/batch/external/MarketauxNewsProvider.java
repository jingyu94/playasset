package com.assetinfo.playasset.batch.external;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.assetinfo.playasset.batch.provider.NewsDataProvider;
import com.assetinfo.playasset.config.ExternalProviderProperties;
import com.fasterxml.jackson.databind.JsonNode;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class MarketauxNewsProvider implements NewsDataProvider {

    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(8);
    private static final String DEFAULT_BASE_URL = "https://api.marketaux.com";

    private final ExternalProviderProperties providerProperties;

    public MarketauxNewsProvider(ExternalProviderProperties providerProperties) {
        this.providerProperties = providerProperties;
    }

    @Override
    public Flux<NewsItem> fetchLatest(List<AssetRef> assets, int maxItems) {
        if (!isEnabled() || assets == null || assets.isEmpty() || maxItems <= 0) {
            return Flux.empty();
        }
        List<AssetRef> candidates = assets.stream()
                .filter(a -> a.symbol() != null && !a.symbol().isBlank())
                .limit(20)
                .toList();
        if (candidates.isEmpty()) {
            return Flux.empty();
        }

        String symbols = candidates.stream()
                .map(AssetRef::symbol)
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .distinct()
                .collect(Collectors.joining(","));
        if (symbols.isBlank()) {
            return Flux.empty();
        }

        String apiKey = providerProperties.getNews().getApiKey().trim();
        return WebClient.builder()
                .baseUrl(baseUrl())
                .build()
                .get()
                .uri(uriBuilder -> uriBuilder
                        .path("/v1/news/all")
                        .queryParam("api_token", apiKey)
                        .queryParam("symbols", symbols)
                        .queryParam("filter_entities", "true")
                        .queryParam("language", "en")
                        .queryParam("limit", Math.max(1, Math.min(50, maxItems)))
                        .build())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .timeout(REQUEST_TIMEOUT)
                .onErrorResume(ex -> Mono.empty())
                .flatMapMany(root -> Flux.fromIterable(parseArticles(root, candidates)))
                .take(maxItems);
    }

    @Override
    public boolean isEnabled() {
        String key = providerProperties.getNews().getApiKey();
        return key != null && !key.isBlank();
    }

    @Override
    public String providerKey() {
        return "MARKETAUX";
    }

    @Override
    public String sourceName() {
        return "marketaux";
    }

    @Override
    public String sourceSiteUrl() {
        return "https://www.marketaux.com";
    }

    private List<NewsItem> parseArticles(JsonNode root, List<AssetRef> assets) {
        if (root == null || !root.has("data") || !root.path("data").isArray()) {
            return List.of();
        }
        List<NewsItem> result = new ArrayList<>();
        for (JsonNode item : root.path("data")) {
            String title = item.path("title").asText("").trim();
            if (title.isBlank()) {
                continue;
            }
            String body = item.path("description").asText("").trim();
            if (body.isBlank()) {
                body = item.path("snippet").asText("").trim();
            }
            String url = item.path("url").asText("").trim();
            String externalId = !url.isBlank() ? sha1(url)
                    : item.path("uuid").asText("").isBlank() ? sha1(title) : item.path("uuid").asText("");
            LocalDateTime publishedAt = parsePublishedAt(item.path("published_at").asText(""))
                    .orElse(LocalDateTime.now());

            List<String> matchedSymbols = new ArrayList<>();
            BigDecimal bestAbsScore = BigDecimal.ZERO;
            BigDecimal chosenScore = BigDecimal.valueOf(0.5);
            if (item.has("entities") && item.path("entities").isArray()) {
                for (JsonNode entity : item.path("entities")) {
                    String symbol = entity.path("symbol").asText("").trim();
                    if (symbol.isBlank()) {
                        continue;
                    }
                    boolean supported = assets.stream()
                            .anyMatch(a -> symbol.equalsIgnoreCase(a.symbol()));
                    if (!supported) {
                        continue;
                    }
                    matchedSymbols.add(symbol);
                    BigDecimal score = parseDecimal(entity.path("sentiment_score").asText(""))
                            .orElse(BigDecimal.valueOf(0.0));
                    BigDecimal abs = score.abs();
                    if (abs.compareTo(bestAbsScore) > 0) {
                        bestAbsScore = abs;
                        chosenScore = score;
                    }
                }
            }

            if (matchedSymbols.isEmpty()) {
                String probe = (title + " " + body).toUpperCase(Locale.ROOT);
                matchedSymbols = assets.stream()
                        .filter(a -> probe.contains(a.symbol().toUpperCase(Locale.ROOT)))
                        .map(AssetRef::symbol)
                        .distinct()
                        .toList();
            }
            if (matchedSymbols.isEmpty()) {
                continue;
            }

            String label = chosenScore.compareTo(BigDecimal.valueOf(0.15)) >= 0 ? "POSITIVE"
                    : chosenScore.compareTo(BigDecimal.valueOf(-0.15)) <= 0 ? "NEGATIVE" : "NEUTRAL";
            BigDecimal normalized = chosenScore.add(BigDecimal.ONE)
                    .divide(BigDecimal.valueOf(2), 5, java.math.RoundingMode.HALF_UP);

            result.add(new NewsItem(
                    externalId,
                    title,
                    body,
                    "en",
                    publishedAt,
                    matchedSymbols.stream().distinct().toList(),
                    label,
                    normalized));
        }
        return result;
    }

    private String baseUrl() {
        String configured = providerProperties.getNews().getBaseUrl();
        if (configured == null || configured.isBlank()) {
            return DEFAULT_BASE_URL;
        }
        return configured;
    }

    private Optional<LocalDateTime> parsePublishedAt(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(OffsetDateTime.parse(value).toLocalDateTime());
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    private Optional<BigDecimal> parseDecimal(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(new BigDecimal(value));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    private String sha1(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-1");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception ex) {
            return Integer.toHexString(value.hashCode());
        }
    }
}
