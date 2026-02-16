package com.assetinfo.playasset.api.v1.dto;

import jakarta.validation.constraints.NotNull;

public record UpdateUserGroupRequest(
        @NotNull Long groupId) {
}
