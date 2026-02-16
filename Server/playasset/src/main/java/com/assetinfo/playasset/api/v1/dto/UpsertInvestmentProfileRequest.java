package com.assetinfo.playasset.api.v1.dto;

import java.util.Map;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UpsertInvestmentProfileRequest(
        @NotBlank @Size(max = 80) String profileKey,
        @NotBlank @Size(max = 120) String profileName,
        @NotBlank @Size(max = 60) String shortLabel,
        @NotBlank @Size(max = 800) String summary,
        @NotNull @Min(0) @Max(200) Integer score,
        @NotNull @Min(1) @Max(10) Integer riskTier,
        @NotBlank @Size(max = 400) String targetAllocationHint,
        Map<String, Integer> answers) {
}
