package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record PortfolioAdviceResponse(
        AdviceMetricsSnapshot metrics,
        List<RebalancingActionSnapshot> rebalancingActions,
        List<EtfRecommendationSnapshot> etfRecommendations,
        AiInsightSnapshot insight) {
}
