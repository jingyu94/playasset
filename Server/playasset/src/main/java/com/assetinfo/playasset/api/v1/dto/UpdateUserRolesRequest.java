package com.assetinfo.playasset.api.v1.dto;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;

public record UpdateUserRolesRequest(
        @NotEmpty List<String> roles) {
}
