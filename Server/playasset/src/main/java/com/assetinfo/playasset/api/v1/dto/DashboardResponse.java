package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;
import java.util.List;

public record DashboardResponse(
        long userId,
        BigDecimal portfolioValue,
        BigDecimal dailyPnl,
        BigDecimal dailyPnlRate,
        int watchlistCount,
        int unreadAlertCount,
        SentimentSnapshot sentiment,
        List<PositionSnapshot> topPositions,
        List<MoverSnapshot> topMovers) {
}
