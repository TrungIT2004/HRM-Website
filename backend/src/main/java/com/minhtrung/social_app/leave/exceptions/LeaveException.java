package com.minhtrung.social_app.leave.exceptions;

import com.minhtrung.social_app.leave.enums.LeaveErrorCode;

public class LeaveException extends RuntimeException {
    private LeaveErrorCode errorCode;

    public LeaveException(LeaveErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }

    public LeaveErrorCode getErrorCode() {
        return this.errorCode;
    }

    public void setErrorCode(LeaveErrorCode errorCode) {
        this.errorCode = errorCode;
    }

}
