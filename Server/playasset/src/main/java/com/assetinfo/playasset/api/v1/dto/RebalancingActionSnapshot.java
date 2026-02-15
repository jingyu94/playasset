package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record RebalancingActionSnapshot(
        long assetId,
        String symbol,
        String assetName,
        String action,
        BigDecimal currentWeightPct,
        BigDecimal targetWeightPct,
        BigDecimal gapPct,
        BigDecimal suggestedAmount,
        int priority,
        String reason) {
}
