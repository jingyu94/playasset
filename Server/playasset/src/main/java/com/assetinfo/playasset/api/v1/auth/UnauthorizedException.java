package com.assetinfo.playasset.api.v1.auth;

public class UnauthorizedException extends RuntimeException {

    public UnauthorizedException(String message) {
        super(message);
    }
}
