package com.minhtrung.hrm.auth.controllers;

import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;
import com.minhtrung.hrm.auth.dtos.requests.ChangePasswordRequest;
import com.minhtrung.hrm.auth.dtos.requests.SignInRequest;
import com.minhtrung.hrm.auth.dtos.requests.SignUpRequest;
import com.minhtrung.hrm.auth.dtos.response.SignInResponse;
import com.minhtrung.hrm.auth.services.AuthService;
import com.minhtrung.hrm.common.context.RequestContext;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/auth")
@Slf4j
public class AuthController {
    private final AuthService authService;

    AuthController(AuthService authService) {
        this.authService = authService;
    }
    
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody SignUpRequest request) {
        authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("message", "User created"));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody SignInRequest signInRequest,
            @CookieValue(value = "deviceId", required = false) UUID deviceId) {

        RequestContext ctx = RequestContextHolder.get();
        if (ctx == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("message", "Missing context"));
        }

        if (deviceId == null) {
            deviceId = UUID.randomUUID();
        }

        ClientMetaData clientMetaData = ctx.getMetaData();
        SignInResponse response = authService.signIn(signInRequest, deviceId, clientMetaData);

        String refreshToken = response.getRefreshToken();

        ResponseCookie refreshCookie = ResponseCookie.from("refreshToken", refreshToken)
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(7 * 24 * 60 * 60) // 7 days
                .sameSite("Lax")
                .build();

        ResponseCookie deviceCookie = ResponseCookie.from("deviceId", deviceId.toString())
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(365 * 24 * 60 * 60) // 1 year
                .sameSite("Lax")
                .build();

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, refreshCookie.toString())
                .header(HttpHeaders.SET_COOKIE, deviceCookie.toString())
                .body(response);
    }
    
    @PostMapping("/auto-login")
    public ResponseEntity<?> autoLogin(@CookieValue(value = "refreshToken", required = false) String token,
            @CookieValue(value = "deviceId", required = false) UUID deviceId) {

        if (token == null || deviceId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Missing cookies"));
        }

        RequestContext ctx = RequestContextHolder.get();
        if (ctx == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("message", "Missing context"));
        }
        
        ClientMetaData clientMetaData = ctx.getMetaData();
        SignInResponse response = authService.autoSignIn(token, deviceId, clientMetaData);

        String refreshToken = response.getRefreshToken();

        ResponseCookie refreshCookie = ResponseCookie.from("refreshToken", refreshToken)
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(7 * 24 * 60 * 60) // 7 days
                .sameSite("Lax")
                .build();

        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, refreshCookie.toString())
                .body(response);
    }
    
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@CookieValue(value = "refreshToken", required = false) String token) {
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
            .header(HttpHeaders.SET_COOKIE, refreshCookie.toString())
            .body(Map.of("message", "Logged out successfully"));
    }

    @PutMapping("/change-password")
    public ResponseEntity<?> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        RequestContext ctx = RequestContextHolder.get();
        if (ctx == null || ctx.getTokenPayload() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Yêu cầu đăng nhập trước khi đổi mật khẩu"));
        }

        UUID userId = ctx.getTokenPayload().getUserId();
        authService.changePassword(userId, request);
        return ResponseEntity.ok(Map.of("message", "Đổi mật khẩu thành công"));
    }
}
