package com.minhtrung.hrm.admin.controllers;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.admin.dtos.requests.AdminResetPasswordRequest;
import com.minhtrung.hrm.admin.dtos.requests.AdminUpdateStatusRequest;
import com.minhtrung.hrm.admin.dtos.requests.CreatePendingUserRequest;
import com.minhtrung.hrm.admin.dtos.requests.ProvisionAccountRequest;
import com.minhtrung.hrm.admin.dtos.requests.RejectPendingUserRequest;
import com.minhtrung.hrm.admin.dtos.requests.SavePermissionsRequest;
import com.minhtrung.hrm.admin.dtos.responses.AdminAccountResponse;
import com.minhtrung.hrm.admin.dtos.responses.AdminSessionResponse;
import com.minhtrung.hrm.admin.dtos.responses.PendingUserResponse;
import com.minhtrung.hrm.admin.dtos.responses.UserPermissionResponse;
import com.minhtrung.hrm.admin.services.AdminService;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Slf4j
public class AdminController {

    private final AdminService adminService;

    // ─── 1. ONBOARDING & PROVISIONING APIS ───────────────────────────

    @GetMapping("/pending-users")
    public ResponseEntity<List<PendingUserResponse>> getPendingUsers(
            @RequestParam(required = false, defaultValue = "PENDING") String status
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(adminService.getPendingUsers(currentUser, status));
    }

    /**
     * HR nhập hồ sơ nhân viên sắp vào làm (bước 1 onboarding).
     * POST /api/admin/pending-users
     */
    @PostMapping("/pending-users")
    public ResponseEntity<PendingUserResponse> createPendingUser(
            @Valid @RequestBody CreatePendingUserRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        PendingUserResponse created = adminService.createPendingUser(request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PostMapping("/pending-users/{pendingId}/provision")
    public ResponseEntity<AdminAccountResponse> provisionUser(
            @PathVariable UUID pendingId,
            @Valid @RequestBody ProvisionAccountRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        AdminAccountResponse response = adminService.provisionUser(pendingId, request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/pending-users/{pendingId}/reject")
    public ResponseEntity<?> rejectPendingUser(
            @PathVariable UUID pendingId,
            @Valid @RequestBody RejectPendingUserRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        adminService.rejectPendingUser(pendingId, request, currentUser);
        return ResponseEntity.ok(Map.of("message", "Đã từ chối hồ sơ tuyển dụng thành công"));
    }

    // ─── 2. ACCOUNT & SECURITY APIS ──────────────────────────────────

    @GetMapping("/accounts")
    public ResponseEntity<List<AdminAccountResponse>> getAllAccounts() {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(adminService.getAllAccounts(currentUser));
    }

    @PatchMapping("/accounts/{userId}/status")
    public ResponseEntity<AdminAccountResponse> updateAccountStatus(
            @PathVariable UUID userId,
            @Valid @RequestBody AdminUpdateStatusRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        AdminAccountResponse response = adminService.updateAccountStatus(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/accounts/{userId}/reset-password")
    public ResponseEntity<?> resetUserPassword(
            @PathVariable UUID userId,
            @Valid @RequestBody AdminResetPasswordRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        adminService.resetUserPassword(userId, request, currentUser);
        return ResponseEntity.ok(Map.of("message", "Đặt lại mật khẩu tạm thời thành công. Đã ngắt các phiên đăng nhập cũ."));
    }

    // ─── 3. SESSIONS & DEVICES MONITORING APIS ───────────────────────

    @GetMapping("/sessions")
    public ResponseEntity<List<AdminSessionResponse>> getAllSessions(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) UUID userId
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(adminService.getAllSessions(currentUser, keyword, userId));
    }

    @GetMapping("/users/{userId}/sessions")
    public ResponseEntity<List<AdminSessionResponse>> getUserSessions(@PathVariable UUID userId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(adminService.getAllSessions(currentUser, null, userId));
    }

    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<?> revokeSession(@PathVariable UUID sessionId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        adminService.revokeSession(sessionId, currentUser);
        return ResponseEntity.ok(Map.of("message", "Đã thu hồi phiên đăng nhập thành công"));
    }

    @DeleteMapping("/users/{userId}/sessions")
    public ResponseEntity<?> revokeAllUserSessions(@PathVariable UUID userId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        adminService.revokeAllUserSessions(userId, currentUser);
        return ResponseEntity.ok(Map.of("message", "Đã đăng xuất toàn bộ thiết bị của nhân viên thành công"));
    }

    // ─── 4. PHÂN QUYỀN THEO NGƯỜI ─────────────────────────────────────

    @GetMapping("/users/{userId}/permissions")
    public ResponseEntity<List<UserPermissionResponse>> getUserPermissions(@PathVariable UUID userId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(adminService.getUserPermissions(userId, currentUser));
    }

    @PutMapping("/users/{userId}/permissions")
    public ResponseEntity<List<UserPermissionResponse>> saveUserPermissions(
            @PathVariable UUID userId,
            @RequestBody SavePermissionsRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        List<UserPermissionResponse> saved = adminService.saveUserPermissions(
                userId, request != null ? request.getPermissions() : null, currentUser);
        return ResponseEntity.ok(saved);
    }
}
