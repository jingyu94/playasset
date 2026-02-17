package com.assetinfo.playasset.batch.external;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.assetinfo.playasset.batch.provider.NewsDataProvider;
import com.fasterxml.jackson.databind.JsonNode;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class GdeltNewsProvider implements NewsDataProvider {

    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(8);
    private static final DateTimeFormatter GDELT_TIME = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'");
    private static final String BASE_URL = "https://api.gdeltproject.org";

    @Override
    public Flux<NewsItem> fetchLatest(List<AssetRef> assets, int maxItems) {
        List<AssetRef> candidates = assets == null ? List.of() : assets.stream()
                .filter(a -> a.symbol() != null && !a.symbol().isBlank())
                .limit(10)
                .toList();
        if (candidates.isEmpty() || maxItems <= 0) {
            return Flux.empty();
        }

        String query = candidates.stream()
                .map(AssetRef::symbol)
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .map(s -> "\"" + s + "\"")
                .collect(Collectors.joining(" OR "));
        if (query.isBlank()) {
            return Flux.empty();
        }

        return WebClient.builder()
                .baseUrl(BASE_URL)
                .build()
                .get()
                .uri(uriBuilder -> uriBuilder
                        .path("/api/v2/doc/doc")
                        .queryParam("query", query + " sourcelang:english")
                        .queryParam("mode", "ArtList")
                        .queryParam("sort", "DateDesc")
                        .queryParam("maxrecords", Math.max(1, Math.min(50, maxItems)))
                        .queryParam("format", "json")
                        .build())
                .retrieve()
                .bodyToMono(JsonNode.class)
                .timeout(REQUEST_TIMEOUT)
                .onErrorResume(ex -> Mono.empty())
                .flatMapMany(node -> Flux.fromIterable(parseArticles(node, candidates)))
                .take(maxItems);
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    @Override
    public String providerKey() {
        return "GDELT";
    }

    @Override
    public String sourceName() {
        return "gdelt";
    }

    @Override
    public String sourceSiteUrl() {
        return "https://www.gdeltproject.org";
    }

    private List<NewsItem> parseArticles(JsonNode root, List<AssetRef> assets) {
        if (root == null || !root.has("articles") || !root.path("articles").isArray()) {
            return List.of();
        }
        List<NewsItem> result = new ArrayList<>();
        for (JsonNode node : root.path("articles")) {
            String title = node.path("title").asText("").trim();
            if (title.isBlank()) {
                continue;
            }
            String url = node.path("url").asText("").trim();
            String body = node.path("seendate").asText("");
            LocalDateTime publishedAt = parseSeenDate(node.path("seendate").asText(""))
                    .orElse(LocalDateTime.now());
            String externalId = !url.isBlank() ? sha1(url) : sha1(title + "|" + publishedAt);

            String probe = (title + " " + node.path("domain").asText("")).toUpperCase(Locale.ROOT);
            List<String> matched = assets.stream()
                    .filter(a -> {
                        String symbol = a.symbol() == null ? "" : a.symbol().toUpperCase(Locale.ROOT);
                        String name = a.assetName() == null ? "" : a.assetName().toUpperCase(Locale.ROOT);
                        return (!symbol.isBlank() && probe.contains(symbol))
                                || (!name.isBlank() && probe.contains(name));
                    })
                    .map(AssetRef::symbol)
                    .distinct()
                    .toList();
            if (matched.isEmpty()) {
                continue;
            }

            result.add(new NewsItem(
                    externalId,
                    title,
                    body,
                    "en",
                    publishedAt,
                    matched,
                    "NEUTRAL",
                    BigDecimal.valueOf(0.50)));
        }
        return result;
    }

    private Optional<LocalDateTime> parseSeenDate(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(LocalDateTime.parse(value, GDELT_TIME));
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
