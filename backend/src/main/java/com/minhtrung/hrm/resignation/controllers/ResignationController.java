package com.minhtrung.hrm.resignation.controllers;

import java.util.Map;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.resignation.dtos.requests.ApproveResignationRequest;
import com.minhtrung.hrm.resignation.dtos.requests.CreateResignationRequest;
import com.minhtrung.hrm.resignation.dtos.requests.TransferRequest;
import com.minhtrung.hrm.resignation.dtos.responses.ResignationResponse;
import com.minhtrung.hrm.resignation.enums.ResignationStatus;
import com.minhtrung.hrm.resignation.services.ResignationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/resignations")
@RequiredArgsConstructor
public class ResignationController {

    private final ResignationService resignationService;

    private UserRole getCurrentUserRole() {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return new UserRole(payload.getUserId(), payload.getDepartment(), payload.getJob());
    }

    /**
     * 1. Nhân viên nộp đơn thôi việc
     * POST /api/resignations
     */
    @PostMapping
    public ResponseEntity<ResignationResponse> createResignationRequest(
            @Valid @RequestBody CreateResignationRequest request) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(resignationService.createResignationRequest(userRole, request));
    }

    /**
     * 2. Cấp 1: Trưởng phòng ban phê duyệt bàn giao (hoặc Từ chối)
     * PUT /api/resignations/transfer
     */
    @PutMapping("/transfer")
    public ResponseEntity<Map<String, String>> transferResignationRequest(
            @Valid @RequestBody TransferRequest request) {
        UserRole userRole = getCurrentUserRole();
        resignationService.transferResignationRequest(userRole, request);
        return ResponseEntity.ok(Map.of("message", "Xử lý duyệt bàn giao đơn thôi việc thành công"));
    }

    /**
     * 3. Cấp 2: Ban Giám Đốc hoặc HR phê duyệt chính thức
     * PUT /api/resignations/approve
     */
    @PutMapping("/approve")
    public ResponseEntity<Map<String, String>> finalizedResignationRequest(
            @Valid @RequestBody ApproveResignationRequest request) {
        UserRole userRole = getCurrentUserRole();
        resignationService.finalizedResignationRequest(userRole, request);
        return ResponseEntity.ok(Map.of("message", "Phê duyệt đơn thôi việc thành công"));
    }

    /**
     * 4. Xem danh sách đơn của cá nhân nhân viên đang đăng nhập
     * GET /api/resignations/my-requests
     */
    @GetMapping("/my-requests")
    public ResponseEntity<Page<ResignationResponse>> getMyResignations(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(resignationService.getMyResignations(userRole, pageable));
    }

    /**
     * 5. Xem danh sách các đơn cần duyệt (cho Trưởng phòng hoặc HR/BGĐ)
     * GET /api/resignations/approvals
     */
    @GetMapping("/approvals")
    public ResponseEntity<Page<ResignationResponse>> getPendingApprovals(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(resignationService.getPendingApprovals(userRole, pageable));
    }

    /**
     * 6. Xem toàn bộ đơn thôi việc của công ty (Dành cho HR / BGĐ)
     * GET /api/resignations/company
     */
    @GetMapping("/company")
    public ResponseEntity<Page<ResignationResponse>> getAllCompanyResignations(
            @RequestParam(required = false) ResignationStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(resignationService.getAllCompanyResignations(userRole, status, pageable));
    }

    /**
     * 7. Nhân viên hủy đơn xin thôi việc của chính mình (chỉ khi đang ở trạng thái PENDING)
     * PATCH /api/resignations/{resignationId}/cancel
     */
    @PatchMapping("/{resignationId}/cancel")
    public ResponseEntity<Map<String, String>> cancelResignationRequest(
            @PathVariable UUID resignationId) {
        UserRole userRole = getCurrentUserRole();
        resignationService.cancelResignationRequest(userRole, resignationId);
        return ResponseEntity.ok(Map.of("message", "Đã hủy đơn xin thôi việc thành công"));
    }
}
