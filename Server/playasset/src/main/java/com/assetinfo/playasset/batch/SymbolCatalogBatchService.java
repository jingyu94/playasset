package com.assetinfo.playasset.batch;

import java.time.LocalDateTime;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.assetinfo.playasset.api.v1.quota.PaidServiceKeys;
import com.assetinfo.playasset.api.v1.quota.PaidServiceQuotaService;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.AssetCatalogUpsertCommand;
import com.assetinfo.playasset.batch.provider.SymbolCatalogProvider;
import com.assetinfo.playasset.batch.provider.SymbolCatalogProvider.SymbolCatalogItem;

@Component
public class SymbolCatalogBatchService {

    private static final Logger log = LoggerFactory.getLogger(SymbolCatalogBatchService.class);

    private final PlatformQueryRepository repository;
    private final SymbolCatalogProvider symbolCatalogProvider;
    private final PaidServiceQuotaService quotaService;

    public SymbolCatalogBatchService(
            PlatformQueryRepository repository,
            SymbolCatalogProvider symbolCatalogProvider,
            PaidServiceQuotaService quotaService) {
        this.repository = repository;
        this.symbolCatalogProvider = symbolCatalogProvider;
        this.quotaService = quotaService;
    }

    @Scheduled(
            cron = "${app.batch.symbol-sync-cron:0 30 7,20 * * *}",
            zone = "${app.batch.zone:Asia/Seoul}")
    public void syncSymbolCatalog() {
        syncSymbolCatalogInternal(false);
    }

    public int syncSymbolCatalogNow(int maxSymbols) {
        return syncSymbolCatalogInternal(true, maxSymbols);
    }

    private void syncSymbolCatalogInternal(boolean manualTrigger) {
        syncSymbolCatalogInternal(manualTrigger, 3000);
    }

    private int syncSymbolCatalogInternal(boolean manualTrigger, int maxSymbols) {
        LocalDateTime startedAt = LocalDateTime.now();
        try {
            quotaService.consume(PaidServiceKeys.SYMBOL_CATALOG_SYNC);
            List<SymbolCatalogItem> items = symbolCatalogProvider.fetchUsSymbols(maxSymbols);
            List<AssetCatalogUpsertCommand> upserts = items.stream()
                    .map(item -> new AssetCatalogUpsertCommand(
                            item.symbol().toUpperCase(),
                            item.assetName(),
                            item.market(),
                            item.currency().toUpperCase()))
                    .toList();
            repository.batchUpsertAssetCatalog(upserts);
            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "SYMBOL_CATALOG_SYNC",
                    symbolCatalogProvider.providerKey(),
                    items.size(),
                    upserts.size(),
                    "SUCCEEDED",
                    null,
                    startedAt,
                    finishedAt);
            log.info("symbol sync finished: provider={}, records={}, manual={}",
                    symbolCatalogProvider.providerKey(),
                    upserts.size(),
                    manualTrigger);
            return upserts.size();
        } catch (Exception ex) {
            LocalDateTime finishedAt = LocalDateTime.now();
            repository.insertIngestionJob(
                    "SYMBOL_CATALOG_SYNC",
                    symbolCatalogProvider.providerKey(),
                    0,
                    0,
                    "FAILED",
                    ex.getMessage(),
                    startedAt,
                    finishedAt);
            log.error("symbol sync failed", ex);
            return 0;
        }
    }
}
