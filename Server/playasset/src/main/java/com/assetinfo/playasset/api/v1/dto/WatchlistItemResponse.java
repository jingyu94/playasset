package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record WatchlistItemResponse(
        long assetId,
        String symbol,
        String assetName,
        BigDecimal lastPrice,
        BigDecimal changeRate,
        String note) {
}
