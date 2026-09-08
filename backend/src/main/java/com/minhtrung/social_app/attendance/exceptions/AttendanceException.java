package com.minhtrung.social_app.attendance.exceptions;

import com.minhtrung.social_app.attendance.enums.AttendanceErrorCode;

public class AttendanceException extends RuntimeException {
    private AttendanceErrorCode errorCode;

    public AttendanceException(AttendanceErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }

    public AttendanceErrorCode getErrorCode() {
        return this.errorCode;
    }

    public void setErrorCode(AttendanceErrorCode errorCode) {
        this.errorCode = errorCode;
    }
}
