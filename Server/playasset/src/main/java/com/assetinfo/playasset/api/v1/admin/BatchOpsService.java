package com.assetinfo.playasset.api.v1.admin;

import org.springframework.stereotype.Service;

import com.assetinfo.playasset.api.v1.dto.BatchJobTriggerResponse;
import com.assetinfo.playasset.batch.MarketNewsBatchService;
import com.assetinfo.playasset.batch.SymbolCatalogBatchService;

@Service
public class BatchOpsService {

    private final MarketNewsBatchService marketNewsBatchService;
    private final SymbolCatalogBatchService symbolCatalogBatchService;

    public BatchOpsService(
            MarketNewsBatchService marketNewsBatchService,
            SymbolCatalogBatchService symbolCatalogBatchService) {
        this.marketNewsBatchService = marketNewsBatchService;
        this.symbolCatalogBatchService = symbolCatalogBatchService;
    }

    public BatchJobTriggerResponse triggerMarketRefresh() {
        marketNewsBatchService.refreshMarketSnapshotNow();
        return new BatchJobTriggerResponse("MARKET_SNAPSHOT", "TRIGGERED", 0);
    }

    public BatchJobTriggerResponse triggerNewsRefresh() {
        marketNewsBatchService.refreshNewsSentimentNow();
        return new BatchJobTriggerResponse("NEWS_SENTIMENT_REFRESH", "TRIGGERED", 0);
    }

    public BatchJobTriggerResponse triggerSymbolSync(int maxSymbols) {
        int records = symbolCatalogBatchService.syncSymbolCatalogNow(maxSymbols);
        return new BatchJobTriggerResponse("SYMBOL_CATALOG_SYNC", "TRIGGERED", records);
    }
}

