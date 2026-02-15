package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record MoverSnapshot(
        String symbol,
        String assetName,
        BigDecimal openPrice,
        BigDecimal closePrice,
        BigDecimal changeRate) {
}
