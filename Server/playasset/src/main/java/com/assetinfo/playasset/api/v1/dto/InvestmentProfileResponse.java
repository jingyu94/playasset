package com.assetinfo.playasset.api.v1.dto;

import java.util.Map;

public record InvestmentProfileResponse(
        String profileKey,
        String profileName,
        String shortLabel,
        String summary,
        int score,
        int riskTier,
        String targetAllocationHint,
        String updatedAt,
        Map<String, Integer> answers) {
}
