package com.assetinfo.playasset.api.v1.auth;

import java.util.Set;

public record AuthPrincipal(
        long userId,
        String loginId,
        String displayName,
        Set<String> roles) {

    public boolean hasRole(String role) {
        return roles != null && roles.contains(role);
    }
}
