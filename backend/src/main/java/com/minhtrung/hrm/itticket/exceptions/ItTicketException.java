package com.minhtrung.hrm.itticket.exceptions;

import com.minhtrung.hrm.itticket.enums.ItTicketErrorCode;

public class ItTicketException extends RuntimeException {
    private ItTicketErrorCode errorCode;

    public ItTicketException(ItTicketErrorCode errorCode, String msg) {
        super(msg);
        this.errorCode = errorCode;
    }

    public ItTicketErrorCode getErrorCode() {
        return this.errorCode;
    }

    public void setErrorCode(ItTicketErrorCode errorCode) {
        this.errorCode = errorCode;
    }
}
