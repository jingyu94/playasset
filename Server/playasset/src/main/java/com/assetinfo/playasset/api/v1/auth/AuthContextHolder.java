package com.assetinfo.playasset.api.v1.auth;

public final class AuthContextHolder {

    private static final ThreadLocal<AuthPrincipal> CONTEXT = new ThreadLocal<>();

    private AuthContextHolder() {
    }

    public static void set(AuthPrincipal principal) {
        CONTEXT.set(principal);
    }

    public static AuthPrincipal get() {
        return CONTEXT.get();
    }

    public static void clear() {
        CONTEXT.remove();
    }
}
