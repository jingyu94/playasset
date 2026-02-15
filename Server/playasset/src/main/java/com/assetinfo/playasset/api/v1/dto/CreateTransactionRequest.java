package com.assetinfo.playasset.api.v1.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateTransactionRequest(
        @NotNull Long accountId,
        @NotNull Long assetId,
        @NotBlank String side,
        @NotNull @DecimalMin("0.000001") BigDecimal quantity,
        @NotNull @DecimalMin("0.0") BigDecimal price,
        @NotNull @DecimalMin("0.0") BigDecimal fee,
        @NotNull @DecimalMin("0.0") BigDecimal tax,
        String occurredAt) {
}
