package com.assetinfo.playasset.batch;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.CandleUpsertCommand;
import com.assetinfo.playasset.api.v1.service.PlatformCacheEvictService;
import com.assetinfo.playasset.config.ExternalProviderProperties;

@Component
public class MarketNewsBatchService {

    private static final Logger log = LoggerFactory.getLogger(MarketNewsBatchService.class);

    private final PlatformQueryRepository repository;
    private final ExternalProviderProperties providerProperties;
    private final PlatformCacheEvictService cacheEvictService;

    public MarketNewsBatchService(
            PlatformQueryRepository repository,
            ExternalProviderProperties providerProperties,
            PlatformCacheEvictService cacheEvictService) {
        this.repository = repository;
        this.providerProperties = providerProperties;
        this.cacheEvictService = cacheEvictService;
    }

    @Scheduled(
            fixedDelayString = "${app.batch.market-refresh-ms:300000}",
            initialDelayString = "${app.batch.initial-delay-ms:45000}")
    public void refreshMarketSnapshot() {
        LocalDateTime startedAt = LocalDateTime.now();
        String sourceKey = providerProperties.getMarket().getApiKey().isBlank() ? "SYNTHETIC" : "EXTERNAL_API";
        try {
            List<Long> assetIds = repository.findAllAssetIds();
            List<CandleUpsertCommand> commands = new ArrayList<>();
            LocalDateTime candleTime = LocalDateTime.now().truncatedTo(ChronoUnit.DAYS);

            for (Long assetId : assetIds) {
                BigDecimal lastClose = repository.findLatestClosePrice(assetId);
                BigDecimal movement = BigDecimal
                        .valueOf(ThreadLocalRandom.current().nextDouble(-0.025, 0.035))
                        .setScale(6, RoundingMode.HALF_UP);
                BigDecimal openPrice = lastClose;
                BigDecimal closePrice = lastClose.multiply(BigDecimal.ONE.add(movement))
                        .setScale(2, RoundingMode.HALF_UP);
                BigDecimal highPrice = openPrice.max(closePrice).multiply(BigDecimal.valueOf(1.004))
                        .setScale(2, RoundingMode.HALF_UP);
                BigDecimal lowPrice = openPrice.min(closePrice).multiply(BigDecimal.valueOf(0.996))
                        .setScale(2, RoundingMode.HALF_UP);
                BigDecimal volume = BigDecimal.valueOf(ThreadLocalRandom.current().nextLong(250000, 13000000));

                commands.add(new CandleUpsertCommand(
                        assetId,
                        candleTime,
                        openPrice,
                        highPrice,
                        lowPrice,
                        closePrice,
                        volume));
            }

            repository.batchUpsertDailyCandles(commands);
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
            log.info("market batch finished: source={}, records={}", sourceKey, commands.size());
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
        LocalDateTime startedAt = LocalDateTime.now();
        String sourceKey = providerProperties.getNews().getApiKey().isBlank() ? "SYNTHETIC" : "EXTERNAL_API";
        try {
            List<Long> assetIds = repository.findAllAssetIds();
            if (assetIds.isEmpty()) {
                return;
            }

            long sourceId = repository.ensureInternalNewsSource();
            int generated = 0;
            for (int i = 0; i < Math.min(3, assetIds.size()); i++) {
                long assetId = assetIds.get(ThreadLocalRandom.current().nextInt(assetIds.size()));
                String assetName = repository.findAssetName(assetId);
                String[] labels = { "POSITIVE", "NEUTRAL", "NEGATIVE" };
                String sentimentLabel = labels[ThreadLocalRandom.current().nextInt(labels.length)];
                BigDecimal score = (switch (sentimentLabel) {
                    case "POSITIVE" -> BigDecimal.valueOf(ThreadLocalRandom.current().nextDouble(0.65, 0.95));
                    case "NEGATIVE" -> BigDecimal.valueOf(ThreadLocalRandom.current().nextDouble(0.65, 0.95));
                    default -> BigDecimal.valueOf(ThreadLocalRandom.current().nextDouble(0.45, 0.62));
                }).setScale(5, RoundingMode.HALF_UP);

                String title = "%s 관련 실적/수급 변화 감지".formatted(assetName);
                String body = "외부 API 키가 공란이므로 현재는 내부 샘플 배치 데이터로 대체 생성됩니다.";
                String externalId = "sim-" + assetId + "-" + System.currentTimeMillis() + "-" + i;

                repository.insertSyntheticNews(
                        sourceId,
                        assetId,
                        title,
                        body,
                        sentimentLabel,
                        score,
                        externalId);
                generated++;
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
            log.info("news batch finished: source={}, generated={}", sourceKey, generated);
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
}
