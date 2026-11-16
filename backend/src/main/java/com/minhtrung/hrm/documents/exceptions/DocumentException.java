package com.minhtrung.hrm.documents.exceptions;

import com.minhtrung.hrm.documents.enums.DocumentErrorCode;

import lombok.Getter;

@Getter
public class DocumentException extends RuntimeException {
    private final DocumentErrorCode errorCode;

    public DocumentException(DocumentErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
}
