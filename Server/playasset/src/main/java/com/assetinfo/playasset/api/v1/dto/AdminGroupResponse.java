package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record AdminGroupResponse(
        long groupId,
        String groupKey,
        String groupName,
        String groupDesc,
        boolean enabled,
        int memberCount,
        List<String> permissions) {
}
