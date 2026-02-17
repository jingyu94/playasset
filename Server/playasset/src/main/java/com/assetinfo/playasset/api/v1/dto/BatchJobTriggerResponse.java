package com.assetinfo.playasset.api.v1.dto;

public record BatchJobTriggerResponse(
        String jobKey,
        String status,
        int records) {
}

