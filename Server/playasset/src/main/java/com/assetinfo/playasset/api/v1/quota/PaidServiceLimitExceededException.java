package com.assetinfo.playasset.api.v1.quota;

public class PaidServiceLimitExceededException extends RuntimeException {

    public PaidServiceLimitExceededException(String message) {
        super(message);
    }
}
