package com.minhtrung.hrm.auth.controllers;

import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;
import com.minhtrung.hrm.auth.dtos.requests.SignInRequest;
import com.minhtrung.hrm.auth.dtos.requests.SignUpRequest;
import com.minhtrung.hrm.auth.dtos.response.SignInResponse;
import com.minhtrung.hrm.auth.enums.AuthErrorCode;
import com.minhtrung.hrm.auth.exceptions.AuthenticationException;
import com.minhtrung.hrm.auth.services.AuthService;
import com.minhtrung.hrm.common.context.RequestContext;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;

import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import com.minhtrung.hrm.auth.dtos.requests.ChangePasswordRequest;


@RestController
@RequestMapping("/auth")
@Slf4j
public class AuthController {
    private final AuthService authService;

    AuthController(AuthService authService) {
        this.authService = authService;
    }

    // @PostMapping("/send-code")
    // public ResponseEntity<?> verifyAccount(@RequestBody SignUpRequest signUpRequest) {
    //     try {
    //         log.info("POST /auth/send-code called");
    //         authService.sendVerificationCode(signUpRequest);
    //         log.info("POST /auth/send-code Verification code sent to the user's email: {}", signUpRequest.getEmail());
    //         return ResponseEntity.status(200).body("Code sent");
    //     } catch (Exception ex) {
    //         log.error("POST /auth/send-code Request failed");
    //         return ResponseEntity.status(500).body(ex);
    //     }
    // }
    
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody SignUpRequest request) {
        try {
            authService.register(request);
            return ResponseEntity.status(201).body("User created");
        } catch (AuthenticationException ex) {
            AuthErrorCode errorCode = ex.getCode();
            int status;
            String userMsg;

            switch (errorCode) {
                case INVALID_CODE:
                    status = 400;
                    userMsg = "The entered code doesn't match";
                    break;
                case EXPIRED_CODE:
                    status = 400;
                    userMsg = "The entered code is expired";
                default:
                    status = 500;
                    userMsg = "INTERNAL SERVER ERROR";
                    break;
            }

            // log.error("Failed to verify email {}", verifyRequest.getEmail());
            return ResponseEntity.status(status).body(Map.of(
                    errorCode, errorCode,
                    userMsg, userMsg
            ));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody SignInRequest signInRequest,
            @CookieValue(value = "deviceId") UUID deviceId) {

        RequestContext ctx = RequestContextHolder.get();

        if (ctx == null) {
            return ResponseEntity.status(500).body("Missing context");
        }

        try {
            ClientMetaData clientMetaData = ctx.getMetaData();
            SignInResponse response = authService.signIn(signInRequest, deviceId, clientMetaData);

            String refreshToken = response.getRefreshToken();

            ResponseCookie refreshCookie = ResponseCookie.from("refreshToken", refreshToken)
                    .httpOnly(true)
                    .secure(false)
                    .path("/")
                    .maxAge(7 * 24 * 60 * 60) // 7 days
                    .sameSite("Strict")
                    .build();

            return ResponseEntity.ok()
                    .header("Set-Cookie", refreshCookie.toString())
                    .body(response);
        } catch (AuthenticationException ex) {
            AuthErrorCode errorCode = ex.getCode();
            int status;
            String userMsg;

            switch (errorCode) {
                case USER_NOT_FOUND:
                    status = 404;
                    userMsg = "User Not Found";
                    break;
                case USER_CREDENTIALS_INVALID:
                    status = 403;
                    userMsg = "Wrong email/password";
                    break;
                default:
                    status = 401;
                    userMsg = "Authentication failed.";
            }

            return ResponseEntity.status(status).body(Map.of(
                "errorCode",  errorCode.toString(),
                "message", userMsg
            ));
        } catch (Exception ex) {
            return ResponseEntity.status(500).body("Internal Server Error");
        }
    }
    
    @PostMapping("/auto-login")
    public ResponseEntity<?> AutoLogin(@CookieValue(value = "refreshToken") String token,
            @CookieValue(value = "deviceId") UUID deviceId) {

        if (token == null || deviceId.equals(null)) {
            return ResponseEntity.status(404).body("Missing cookies");
        }

        RequestContext ctx = RequestContextHolder.get();

        if (ctx == null) {
            return ResponseEntity.status(500).body("Missing context");
        }
        
        try {
            ClientMetaData clientMetaData = ctx.getMetaData();
            SignInResponse response = authService.autoSignIn(token, deviceId, clientMetaData);

            String refreshToken = response.getRefreshToken();

            ResponseCookie refreshCookie = ResponseCookie.from("refreshToken", refreshToken)
                    .httpOnly(true) // cannot access via JS (IMPORTANT)
                    .secure(false) // true if HTTPS
                    .path("/")
                    .maxAge(7 * 24 * 60 * 60) // 7 days
                    .sameSite("Strict")
                    .build();

            return ResponseEntity.ok()
                    .header("Set-Cookie", refreshCookie.toString())
                    .body(response);
        } catch (AuthenticationException ex) {
            AuthErrorCode code = ex.getCode();   
            int status;
            String userMessage;
    
            switch (code) {
                case SESSION_COMPROMISED:
                    status = 401;
                    userMessage = "Session compromised. Please log in again.";
                    break;
                case SESSION_NOT_FOUND:
                case SESSION_REVOKED:
                case SESSION_MISMATCH:
                    status = 401;
                    userMessage = "Session invalid or expired.";
                    break;
                case USER_MISMATCH:
                case DEVICE_MISMATCH:
                case DEVICE_COOKIE_MISMATCH:
                    status = 403;
                    userMessage = "Session does not match the request.";
                    break;
                default:
                    status = 401;
                    userMessage = "Authentication failed.";
            }

            ResponseCookie deleteCookie = ResponseCookie.from("refreshToken", "")
            .path("/").maxAge(0).httpOnly(true).build();
        
            return ResponseEntity.status(status)
                .header("Set-Cookie", deleteCookie.toString())
                .body(Map.of(
                    "errorCode", code.toString(),   
                    "message", userMessage
            ));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Internal server error");
        }
    }
    
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@CookieValue(value = "refreshToken", required = false) String token) {
        try {
            if (token != null && !token.isBlank()) {
                authService.signOut(token);
            }

            ResponseCookie refreshCookie = ResponseCookie.from("refreshToken", "")
                .httpOnly(true)
                .secure(false) 
                .path("/")     
                .maxAge(0)    
                .build();

            return ResponseEntity.ok()
                .header("Set-Cookie", refreshCookie.toString())
                .body(Map.of("message", "Logged out successfully"));
        } catch(Exception ex) {
            ResponseCookie refreshCookie = ResponseCookie.from("refreshToken", "")
                .httpOnly(true)
                .secure(false) 
                .path("/")     
                .maxAge(0)    
                .build();

            return ResponseEntity.ok()
                .header("Set-Cookie", refreshCookie.toString())
                .body(Map.of("message", "Logged out"));
        }
    }

    @PutMapping("/change-password")
    public ResponseEntity<?> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        RequestContext ctx = RequestContextHolder.get();
        if (ctx == null || ctx.getTokenPayload() == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Yêu cầu đăng nhập trước khi đổi mật khẩu"));
        }

        UUID userId = ctx.getTokenPayload().getUserId();
        try {
            authService.changePassword(userId, request);
            return ResponseEntity.ok(Map.of("message", "Đổi mật khẩu thành công"));
        } catch (AuthenticationException ex) {
            return ResponseEntity.status(400).body(Map.of(
                "errorCode", ex.getCode().toString(),
                "message", ex.getMessage()
            ));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(400).body(Map.of(
                "message", ex.getMessage()
            ));
        } catch (Exception ex) {
            log.error("Lỗi khi đổi mật khẩu cho user: {}", userId, ex);
            return ResponseEntity.status(500).body(Map.of("message", "Lỗi máy chủ nội bộ khi đổi mật khẩu"));
        }
    }
}
