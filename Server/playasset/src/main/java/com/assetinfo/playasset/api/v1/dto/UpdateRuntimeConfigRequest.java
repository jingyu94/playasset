package com.assetinfo.playasset.api.v1.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UpdateRuntimeConfigRequest(
        @NotBlank String configName,
        @NotBlank String valueTypeCd,
        @NotBlank String configValue,
        String configDesc,
        @NotNull Boolean enabled) {
}

