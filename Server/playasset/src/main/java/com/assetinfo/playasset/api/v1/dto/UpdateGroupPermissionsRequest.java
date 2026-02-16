package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;

public record UpdateGroupPermissionsRequest(
        @NotEmpty List<String> permissions) {
}
