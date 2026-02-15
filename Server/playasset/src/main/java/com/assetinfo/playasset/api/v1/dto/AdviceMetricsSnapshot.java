package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record AdviceMetricsSnapshot(
        long userId,
        String asOfDate,
        BigDecimal totalValue,
        BigDecimal expectedAnnualReturnPct,
        BigDecimal annualVolatilityPct,
        BigDecimal sharpeRatio,
        BigDecimal maxDrawdownPct,
        BigDecimal concentrationPct,
        BigDecimal diversificationScore,
        String riskLevel) {
}
