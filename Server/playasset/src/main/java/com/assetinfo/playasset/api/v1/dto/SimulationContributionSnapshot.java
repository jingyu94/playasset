package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record SimulationContributionSnapshot(
        long assetId,
        String symbol,
        String assetName,
        BigDecimal quantity,
        BigDecimal startPrice,
        BigDecimal endPrice,
        BigDecimal pnlAmount,
        BigDecimal pnlRate) {
}
