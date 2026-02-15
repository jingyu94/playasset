package com.assetinfo.playasset.api.v1.dto;

public record PaidServicePolicyResponse(
        String serviceKey,
        String displayName,
        int dailyLimit,
        boolean enabled,
        int usedToday,
        int remainingToday) {
}
