package com.minhtrung.social_app.auth.exceptions;

import com.minhtrung.social_app.auth.enums.AuthErrorCode;

public class AuthenticationException extends RuntimeException {
    private final AuthErrorCode code;
    
    public AuthenticationException(AuthErrorCode code, String message) {
        super(message);
        this.code = code;
    }
    
    public AuthErrorCode getCode() { return code; }
}
