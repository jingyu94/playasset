package com.assetinfo.playasset.api.v1.auth;

public class ForbiddenException extends RuntimeException {

    public ForbiddenException(String message) {
        super(message);
    }
}
