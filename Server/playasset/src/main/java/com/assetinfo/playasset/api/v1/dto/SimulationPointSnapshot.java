package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

public record SimulationPointSnapshot(
        String date,
        BigDecimal simulatedValue,
        BigDecimal cumulativeReturnPct,
        BigDecimal drawdownPct) {
}
