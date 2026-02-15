package com.assetinfo.playasset.api.v1.dto;

import java.time.Instant;

public record ApiResponse<T>(boolean success, String timestamp, T data) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, Instant.now().toString(), data);
    }
}
