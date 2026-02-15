package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record EtfRecommendationSnapshot(
        long etfId,
        String symbol,
        String name,
        String market,
        String focusTheme,
        String riskBucket,
        BigDecimal expenseRatioPct,
        BigDecimal suggestedWeightPct,
        int matchScore,
        String reason) {
}
