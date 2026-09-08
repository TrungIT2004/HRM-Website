package com.minhtrung.social_app.overtime.exceptions;

import com.minhtrung.social_app.overtime.enums.OvertimeErrorCode;

public class OvertimeException extends RuntimeException {
    OvertimeErrorCode errorCode;

    public OvertimeException(OvertimeErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }

    public OvertimeErrorCode getErrorCode() {
        return this.errorCode;
    }

    public void setErrorCode(OvertimeErrorCode errorCode) {
        this.errorCode = errorCode;
    }

}
