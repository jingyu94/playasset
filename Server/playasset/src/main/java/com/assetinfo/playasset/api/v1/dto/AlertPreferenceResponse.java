package com.assetinfo.playasset.api.v1.dto;

public record AlertPreferenceResponse(
        long userId,
        boolean lowEnabled,
        boolean mediumEnabled,
        boolean highEnabled) {
}

