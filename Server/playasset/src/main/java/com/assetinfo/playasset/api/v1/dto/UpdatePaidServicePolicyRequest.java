package com.assetinfo.playasset.api.v1.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UpdatePaidServicePolicyRequest(
        @NotBlank String displayName,
        @NotNull @Min(0) Integer dailyLimit,
        @NotNull Boolean enabled) {
}
