package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record AdminUserResponse(
        long userId,
        String loginId,
        String displayName,
        String status,
        Long groupId,
        String groupName,
        List<String> roles) {
}
