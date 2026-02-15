package com.assetinfo.playasset.api.v1.dto;

public record AlertResponse(
        long alertEventId,
        String eventType,
        String title,
        String message,
        String severity,
        String status,
        String occurredAt) {
}
