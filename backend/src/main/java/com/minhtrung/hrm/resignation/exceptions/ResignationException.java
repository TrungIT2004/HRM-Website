package com.minhtrung.hrm.resignation.exceptions;

import com.minhtrung.hrm.resignation.enums.ResignationErrorCode;
import lombok.Getter;

@Getter
public class ResignationException extends RuntimeException {
    private final ResignationErrorCode errorCode;

    public ResignationException(ResignationErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
}
