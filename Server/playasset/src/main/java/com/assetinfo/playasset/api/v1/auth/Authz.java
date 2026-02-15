package com.assetinfo.playasset.api.v1.auth;

public final class Authz {

    private Authz() {
    }

    public static AuthPrincipal requireAuthenticated() {
        AuthPrincipal principal = AuthContextHolder.get();
        if (principal == null) {
            throw new UnauthorizedException("로그인이 필요합니다.");
        }
        return principal;
    }

    public static AuthPrincipal requireAdmin() {
        AuthPrincipal principal = requireAuthenticated();
        if (!principal.hasRole("ADMIN")) {
            throw new ForbiddenException("관리자 권한이 필요합니다.");
        }
        return principal;
    }

    public static AuthPrincipal requireUserOrAdmin(long userId) {
        AuthPrincipal principal = requireAuthenticated();
        if (principal.userId() != userId && !principal.hasRole("ADMIN")) {
            throw new ForbiddenException("해당 사용자 리소스 접근 권한이 없습니다.");
        }
        return principal;
    }
}
