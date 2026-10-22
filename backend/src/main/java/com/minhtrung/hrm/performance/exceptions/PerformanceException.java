package com.minhtrung.hrm.performance.exceptions;

import com.minhtrung.hrm.performance.enums.PerformanceErrorCode;

public class PerformanceException extends RuntimeException {
    PerformanceErrorCode errorCode;

    public PerformanceException(PerformanceErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }

    public PerformanceErrorCode getErrorCode() {
        return this.errorCode;
    }

    public void setErrorCode(PerformanceErrorCode errorCode) {
        this.errorCode = errorCode;
    }
}
