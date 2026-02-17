package com.assetinfo.playasset.batch.provider;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import reactor.core.publisher.Flux;

public interface NewsDataProvider {

    Flux<NewsItem> fetchLatest(List<AssetRef> assets, int maxItems);

    boolean isEnabled();

    String providerKey();

    String sourceName();

    String sourceSiteUrl();

    record AssetRef(
            long assetId,
            String symbol,
            String assetName,
            String market,
            String currency) {
    }

    record NewsItem(
            String externalId,
            String title,
            String body,
            String language,
            LocalDateTime publishedAt,
            List<String> matchedSymbols,
            String sentimentLabel,
            BigDecimal sentimentScore) {
    }
}
