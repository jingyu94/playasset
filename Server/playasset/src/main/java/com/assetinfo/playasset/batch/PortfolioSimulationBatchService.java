package com.assetinfo.playasset.batch;

import java.time.LocalDateTime;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.api.v1.service.PlatformCacheEvictService;
import com.assetinfo.playasset.api.v1.service.PlatformService;

@Component
public class PortfolioSimulationBatchService {

    private static final Logger log = LoggerFactory.getLogger(PortfolioSimulationBatchService.class);

    private final PlatformQueryRepository repository;
    private final PlatformService platformService;
    private final PlatformCacheEvictService cacheEvictService;

    @Value("${app.batch.simulator-lookback-days:730}")
    private int lookbackDays;

    public PortfolioSimulationBatchService(
            PlatformQueryRepository repository,
            PlatformService platformService,
            PlatformCacheEvictService cacheEvictService) {
        this.repository = repository;
        this.platformService = platformService;
        this.cacheEvictService = cacheEvictService;
    }

    @Scheduled(
            fixedDelayString = "${app.batch.simulator-refresh-ms:21600000}",
            initialDelayString = "${app.batch.initial-delay-ms:45000}")
    public void refreshPortfolioSimulationCache() {
        LocalDateTime startedAt = LocalDateTime.now();
        try {
            List<Long> userIds = repository.findUsersWithOpenPositions();
            int records = 0;
            for (Long userId : userIds) {
                records += platformService.rebuildSimulationCacheForUser(userId, lookbackDays);
            }
            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "PORTFOLIO_SIMULATION_CACHE",
                    "INTERNAL",
                    userIds.size(),
                    records,
                    "SUCCEEDED",
                    null,
                    startedAt,
                    finishedAt);
            cacheEvictService.evictSimulationCaches();
            log.info("simulation cache batch finished: users={}, records={}", userIds.size(), records);
        } catch (Exception ex) {
            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "PORTFOLIO_SIMULATION_CACHE",
                    "INTERNAL",
                    0,
                    0,
                    "FAILED",
                    ex.getMessage(),
                    startedAt,
                    finishedAt);
            log.error("simulation cache batch failed", ex);
        }
    }
}
