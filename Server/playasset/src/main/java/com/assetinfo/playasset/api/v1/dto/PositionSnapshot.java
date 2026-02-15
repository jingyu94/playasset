package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record PositionSnapshot(
        long assetId,
        String symbol,
        String assetName,
        BigDecimal quantity,
        BigDecimal avgCost,
        BigDecimal currentPrice,
        BigDecimal valuation,
        BigDecimal pnlRate) {
}
