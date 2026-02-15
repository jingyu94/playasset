package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

public record AiInsightSnapshot(
        String headline,
        String summary,
        List<String> keyPoints,
        List<String> cautions,
        String generatedAt,
        String model) {
}
