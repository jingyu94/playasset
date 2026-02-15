package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record CreateTransactionResponse(
        long transactionId,
        long accountId,
        long assetId,
        String side,
        BigDecimal quantity,
        BigDecimal price,
        BigDecimal positionQuantity,
        BigDecimal avgCost,
        BigDecimal realizedPnl) {
}
