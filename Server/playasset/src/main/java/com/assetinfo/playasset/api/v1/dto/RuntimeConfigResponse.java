package com.assetinfo.playasset.api.v1.dto;

public record RuntimeConfigResponse(
        long runtimeConfigId,
        String configGroupCd,
        String configKey,
        String configName,
        String valueTypeCd,
        String configValue,
        String configDesc,
        int sortNo,
        boolean editable,
        boolean enabled,
        String updatedAt) {
}

