package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;
import java.util.List;

public record PortfolioSimulationResponse(
        long userId,
        String startDate,
        String endDate,
        int simulationDays,
        BigDecimal startValue,
        BigDecimal endValue,
        BigDecimal pnlAmount,
        BigDecimal pnlRate,
        BigDecimal annualizedReturnPct,
        BigDecimal maxDrawdownPct,
        List<SimulationPointSnapshot> timeline,
        List<SimulationContributionSnapshot> contributions,
        List<String> notes) {
}
