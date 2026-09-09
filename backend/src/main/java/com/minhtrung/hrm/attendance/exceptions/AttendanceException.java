package com.minhtrung.hrm.attendance.exceptions;

import com.minhtrung.hrm.attendance.enums.AttendanceErrorCode;

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
