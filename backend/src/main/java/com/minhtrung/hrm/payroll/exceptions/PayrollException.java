package com.minhtrung.hrm.payroll.exceptions;

import com.minhtrung.hrm.payroll.enums.PayrollErrorCode;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PayrollException extends RuntimeException {
    private PayrollErrorCode errorCode;

    public PayrollException(PayrollErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }
}
