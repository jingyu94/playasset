package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record CurrentUserResponse(
        long userId,
        String loginId,
        String displayName,
        List<String> roles) {
}
