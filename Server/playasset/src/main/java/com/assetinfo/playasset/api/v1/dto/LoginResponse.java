package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record LoginResponse(
        String accessToken,
        String tokenType,
        String expiresAt,
        long userId,
        String loginId,
        String displayName,
        List<String> roles) {
}
