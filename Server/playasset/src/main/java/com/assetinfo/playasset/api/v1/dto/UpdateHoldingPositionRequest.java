package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

public record UpdateHoldingPositionRequest(
        @NotNull @DecimalMin("0.0") BigDecimal quantity,
        @NotNull @DecimalMin("0.0") BigDecimal avgCost) {
}
