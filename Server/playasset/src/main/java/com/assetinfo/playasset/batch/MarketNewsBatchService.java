package com.assetinfo.playasset.batch;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.assetinfo.playasset.api.v1.quota.PaidServiceKeys;
import com.assetinfo.playasset.api.v1.quota.PaidServiceQuotaService;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.AssetMarketSyncTarget;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.CandleUpsertCommand;
import com.assetinfo.playasset.api.v1.service.PlatformCacheEvictService;
import com.assetinfo.playasset.api.v1.service.RuntimeConfigService;
import com.assetinfo.playasset.batch.provider.FxRateProvider;
import com.assetinfo.playasset.batch.provider.MarketDataProvider;
import com.assetinfo.playasset.batch.provider.MarketDataProvider.QuoteSnapshot;
import com.assetinfo.playasset.batch.provider.NewsDataProvider;
import com.assetinfo.playasset.batch.provider.NewsDataProvider.AssetRef;
import com.assetinfo.playasset.batch.provider.NewsDataProvider.NewsItem;
import com.assetinfo.playasset.config.ExternalProviderProperties;

import reactor.core.publisher.Flux;

@Component
public class MarketNewsBatchService {

    private static final Logger log = LoggerFactory.getLogger(MarketNewsBatchService.class);

    private final PlatformQueryRepository repository;
    private final ExternalProviderProperties providerProperties;
    private final PlatformCacheEvictService cacheEvictService;
    private final PaidServiceQuotaService quotaService;
    private final List<MarketDataProvider> marketDataProviders;
    private final List<NewsDataProvider> newsDataProviders;
    private final FxRateProvider fxRateProvider;
    private final RuntimeConfigService runtimeConfigService;

    public MarketNewsBatchService(
            PlatformQueryRepository repository,
            ExternalProviderProperties providerProperties,
            PlatformCacheEvictService cacheEvictService,
            PaidServiceQuotaService quotaService,
            List<MarketDataProvider> marketDataProviders,
            List<NewsDataProvider> newsDataProviders,
            FxRateProvider fxRateProvider,
            RuntimeConfigService runtimeConfigService) {
        this.repository = repository;
        this.providerProperties = providerProperties;
        this.cacheEvictService = cacheEvictService;
        this.quotaService = quotaService;
        this.marketDataProviders = marketDataProviders;
        this.newsDataProviders = newsDataProviders;
        this.fxRateProvider = fxRateProvider;
        this.runtimeConfigService = runtimeConfigService;
    }

    @Scheduled(
            fixedDelayString = "${app.batch.market-refresh-ms:300000}",
            initialDelayString = "${app.batch.initial-delay-ms:45000}")
    public void refreshMarketSnapshot() {
        refreshMarketSnapshotInternal(false);
    }

    public void refreshMarketSnapshotNow() {
        refreshMarketSnapshotInternal(true);
    }

    private void refreshMarketSnapshotInternal(boolean manualTrigger) {
        LocalDateTime startedAt = LocalDateTime.now();
        boolean marketConfigured = !providerProperties.getMarket().getApiKey().isBlank()
                && !providerProperties.getMarket().getBaseUrl().isBlank();
        String sourceKey = marketConfigured ? "EXTERNAL_API" : "NO_EXTERNAL_PROVIDER";
        try {
            quotaService.consume(PaidServiceKeys.MARKET_BATCH_REFRESH);
            List<AssetMarketSyncTarget> assets = repository.findAllAssetSyncTargets();
            List<CandleUpsertCommand> commands = new ArrayList<>();
            LocalDateTime candleTime = LocalDateTime.now().truncatedTo(ChronoUnit.DAYS);
            BigDecimal usdKrwRate = fxRateProvider.fetchUsdKrw().orElse(BigDecimal.valueOf(1300));
            int externalMaxSymbols = Math.max(0, providerProperties.getMarket().getFreeMaxSymbols());
            int externalUsed = 0;
            Map<Long, QuoteSnapshot> quoteByAssetId = new HashMap<>();
            Set<String> providerKeys = new java.util.LinkedHashSet<>();

            for (MarketDataProvider provider : marketDataProviders) {
                List<AssetMarketSyncTarget> candidates = assets.stream()
                        .filter(asset -> provider.supports(asset.market(), asset.symbol(), asset.currency()))
                        .toList();
                if (candidates.isEmpty()) {
                    continue;
                }
                if ("TWELVE_DATA".equals(provider.providerKey())) {
                    if (!marketConfigured || externalMaxSymbols <= 0) {
                        continue;
                    }
                    candidates = candidates.stream().limit(externalMaxSymbols).toList();
                }

                Map<String, QuoteSnapshot> quoteBySymbol = provider.fetchQuotes(
                        candidates.stream()
                                .map(AssetMarketSyncTarget::symbol)
                                .collect(Collectors.toList()));
                for (AssetMarketSyncTarget candidate : candidates) {
                    QuoteSnapshot quote = quoteBySymbol.get(candidate.symbol());
                    if (quote != null) {
                        quoteByAssetId.put(candidate.assetId(), quote);
                        providerKeys.add(provider.providerKey());
                    }
                }
            }

            for (AssetMarketSyncTarget asset : assets) {
                Optional<QuoteSnapshot> quoteSnapshot = Optional.ofNullable(quoteByAssetId.get(asset.assetId()));
                if (quoteSnapshot.isPresent()) {
                    externalUsed++;
                    QuoteSnapshot quote = quoteSnapshot.get();
                    boolean usdAsset = "USD".equalsIgnoreCase(asset.currency());
                    BigDecimal fx = usdAsset ? usdKrwRate : BigDecimal.ONE;
                    commands.add(new CandleUpsertCommand(
                            asset.assetId(),
                            candleTime,
                            toKrw(quote.openPrice(), fx),
                            toKrw(quote.highPrice(), fx),
                            toKrw(quote.lowPrice(), fx),
                            toKrw(quote.closePrice(), fx),
                            quote.volume().setScale(0, RoundingMode.HALF_UP)));
                }
            }

            repository.batchUpsertDailyCandles(commands);
            if (externalUsed > 0) {
                sourceKey = "EXTERNAL_" + String.join("+", providerKeys);
            } else {
                sourceKey = marketConfigured ? "NO_EXTERNAL_DATA" : "NO_EXTERNAL_PROVIDER";
            }

            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "MARKET_SNAPSHOT",
                    sourceKey,
                    commands.size(),
                    commands.size(),
                    "SUCCEEDED",
                    null,
                    startedAt,
                    finishedAt);
            cacheEvictService.evictMarketDrivenCaches();
            log.info(
                    "market batch finished: source={}, records={}, externalUsed={}, usdKrw={}, providers={}, manual={}",
                    sourceKey,
                    commands.size(),
                    externalUsed,
                    usdKrwRate,
                    providerKeys,
                    manualTrigger);
        } catch (Exception ex) {
            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "MARKET_SNAPSHOT",
                    sourceKey,
                    0,
                    0,
                    "FAILED",
                    ex.getMessage(),
                    startedAt,
                    finishedAt);
            log.error("market batch failed", ex);
        }
    }

    @Scheduled(
            fixedDelayString = "${app.batch.news-refresh-ms:420000}",
            initialDelayString = "${app.batch.initial-delay-ms:45000}")
    public void refreshNewsSentiment() {
        refreshNewsSentimentInternal(false);
    }

    public void refreshNewsSentimentNow() {
        refreshNewsSentimentInternal(true);
    }

    private void refreshNewsSentimentInternal(boolean manualTrigger) {
        LocalDateTime startedAt = LocalDateTime.now();
        String sourceKey = "SYNTHETIC";
        try {
            quotaService.consume(PaidServiceKeys.NEWS_BATCH_REFRESH);
            List<AssetMarketSyncTarget> assets = repository.findAllAssetSyncTargets();
            if (assets.isEmpty()) {
                return;
            }

            List<Long> prioritizedAssetIds = repository.findPrioritizedNewsAssetIds(30);
            Map<String, Long> assetIdBySymbol = new LinkedHashMap<>();
            List<AssetRef> refs = buildNewsAssetRefs(assets, prioritizedAssetIds, assetIdBySymbol);

            int maxPerProvider = Math.max(3, Math.min(30, refs.size()));
            List<NewsDataProvider> activeProviders = newsDataProviders.stream()
                    .filter(NewsDataProvider::isEnabled)
                    .toList();

            List<ProviderNews> externalNews = Flux.merge(
                    activeProviders.stream()
                            .map(provider -> provider.fetchLatest(refs, maxPerProvider)
                                    .map(item -> new ProviderNews(provider, item))
                                    .onErrorResume(ex -> Flux.empty()))
                            .toList())
                    .take(Math.max(8, maxPerProvider * Math.max(1, activeProviders.size())))
                    .collectList()
                    .blockOptional()
                    .orElse(List.of());

            int generated = 0;
            if (!externalNews.isEmpty()) {
                Set<String> providerKeys = new java.util.LinkedHashSet<>();
                for (ProviderNews row : externalNews) {
                    NewsDataProvider provider = row.provider();
                    NewsItem item = row.item();
                    long sourceId = repository.ensureNewsSource(provider.sourceName(), provider.sourceSiteUrl());
                    providerKeys.add(provider.providerKey());
                    for (String symbol : item.matchedSymbols()) {
                        Long assetId = assetIdBySymbol.get(symbol.trim().toUpperCase());
                        if (assetId == null) {
                            continue;
                        }
                        repository.upsertNewsArticleWithMention(
                                sourceId,
                                assetId,
                                item.title(),
                                item.body(),
                                item.language(),
                                item.publishedAt(),
                                item.sentimentLabel(),
                                item.sentimentScore(),
                                item.externalId(),
                                "news-v1",
                                BigDecimal.valueOf(0.8));
                        generated++;
                    }
                }
                sourceKey = "EXTERNAL_" + String.join("+", providerKeys);
            }

            if (generated == 0) {
                generated = generateSyntheticNews(assets, prioritizedAssetIds);
                sourceKey = "SYNTHETIC";
            }

            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "NEWS_SENTIMENT_REFRESH",
                    sourceKey,
                    generated,
                    generated,
                    "SUCCEEDED",
                    null,
                    startedAt,
                    finishedAt);
            cacheEvictService.evictNewsDrivenCaches();
            log.info(
                    "news batch finished: source={}, generated={}, providers={}, prioritizedAssets={}, manual={}",
                    sourceKey,
                    generated,
                    activeProviders.stream().map(NewsDataProvider::providerKey).toList(),
                    prioritizedAssetIds.size(),
                    manualTrigger);
        } catch (Exception ex) {
            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "NEWS_SENTIMENT_REFRESH",
                    sourceKey,
                    0,
                    0,
                    "FAILED",
                    ex.getMessage(),
                    startedAt,
                    finishedAt);
            log.error("news batch failed", ex);
        }
    }

    private int generateSyntheticNews(List<AssetMarketSyncTarget> assets, List<Long> prioritizedAssetIds) {
        List<Long> fallbackAssetIds = assets.stream().map(AssetMarketSyncTarget::assetId).toList();
        List<Long> assetIds = prioritizedAssetIds == null || prioritizedAssetIds.isEmpty() ? fallbackAssetIds
                : prioritizedAssetIds;
        if (assetIds.isEmpty()) {
            return 0;
        }
        long sourceId = repository.ensureInternalNewsSource();
        int generated = 0;
        int maxItems = Math.min(3, assetIds.size());
        for (int i = 0; i < maxItems; i++) {
            long assetId = assetIds.get(ThreadLocalRandom.current().nextInt(assetIds.size()));
            String assetName = repository.findAssetName(assetId);
            String[] labels = { "POSITIVE", "NEUTRAL", "NEGATIVE" };
            String sentimentLabel = labels[ThreadLocalRandom.current().nextInt(labels.length)];
            BigDecimal score = (switch (sentimentLabel) {
                case "POSITIVE" -> BigDecimal.valueOf(ThreadLocalRandom.current().nextDouble(0.65, 0.95));
                case "NEGATIVE" -> BigDecimal.valueOf(ThreadLocalRandom.current().nextDouble(0.65, 0.95));
                default -> BigDecimal.valueOf(ThreadLocalRandom.current().nextDouble(0.45, 0.62));
            }).setScale(5, RoundingMode.HALF_UP);

            String titleTemplate = batchMessage("news.synthetic.title.template", "%s 관련 수급/모멘텀 업데이트");
            String bodyTemplate = batchMessage("news.synthetic.body.template",
                    "외부 뉴스 API 키가 없어 내부 샘플 데이터로 생성했어요.");
            String title = titleTemplate.formatted(assetName);
            String body = bodyTemplate;
            String externalId = "sim-" + assetId + "-" + System.currentTimeMillis() + "-" + i;

            repository.insertSyntheticNews(sourceId, assetId, title, body, sentimentLabel, score, externalId);
            generated++;
        }
        return generated;
    }

    private List<AssetRef> buildNewsAssetRefs(
            List<AssetMarketSyncTarget> assets,
            List<Long> prioritizedAssetIds,
            Map<String, Long> assetIdBySymbol) {
        Map<Long, AssetMarketSyncTarget> byId = assets.stream()
                .collect(Collectors.toMap(AssetMarketSyncTarget::assetId, a -> a, (a, b) -> a, LinkedHashMap::new));
        List<AssetRef> ordered = new ArrayList<>();
        Set<Long> used = new HashSet<>();
        for (Long assetId : prioritizedAssetIds) {
            AssetMarketSyncTarget asset = byId.get(assetId);
            if (asset == null || used.contains(asset.assetId())) {
                continue;
            }
            used.add(asset.assetId());
            ordered.add(toAssetRef(asset, assetIdBySymbol));
        }
        for (AssetMarketSyncTarget asset : assets) {
            if (ordered.size() >= 30) {
                break;
            }
            if (used.contains(asset.assetId())) {
                continue;
            }
            used.add(asset.assetId());
            ordered.add(toAssetRef(asset, assetIdBySymbol));
        }
        return ordered;
    }

    private AssetRef toAssetRef(AssetMarketSyncTarget asset, Map<String, Long> assetIdBySymbol) {
        String normalized = asset.symbol().trim().toUpperCase();
        assetIdBySymbol.put(normalized, asset.assetId());
        return new AssetRef(
                asset.assetId(),
                asset.symbol(),
                asset.assetName(),
                asset.market(),
                asset.currency());
    }

    private String batchMessage(String key, String defaultValue) {
        return runtimeConfigService.getString(RuntimeConfigService.GROUP_MARKET_BATCH_MESSAGE, key, defaultValue);
    }

    private BigDecimal toKrw(BigDecimal value, BigDecimal fxRate) {
        return value.multiply(fxRate).setScale(2, RoundingMode.HALF_UP);
    }

    private record ProviderNews(NewsDataProvider provider, NewsItem item) {
    }
}
