package com.minhtrung.hrm.asset.exceptions;

import com.minhtrung.hrm.asset.enums.AssetErrorCode;

public class AssetException extends RuntimeException {
    private AssetErrorCode errorCode;

    public AssetException(AssetErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }

    public AssetErrorCode getErrorCode() {
        return this.errorCode;
    }

    public void setErrorCode(AssetErrorCode errorCode) {
        this.errorCode = errorCode;
    }
}
