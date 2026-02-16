package com.assetinfo.playasset.api.v1.dto;

import jakarta.validation.constraints.NotNull;

public record UpdateAlertPreferenceRequest(
        @NotNull Boolean lowEnabled,
        @NotNull Boolean mediumEnabled,
        @NotNull Boolean highEnabled) {
}

