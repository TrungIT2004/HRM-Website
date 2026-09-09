package com.minhtrung.hrm.leave.controllers;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.leave.dtos.requests.CreateLeaveReqRequest;
import com.minhtrung.hrm.leave.dtos.requests.HandleLeaveReqApiRequest;
import com.minhtrung.hrm.leave.dtos.requests.LeaveFilterRequest;
import com.minhtrung.hrm.leave.dtos.responses.HrLeaveResponse;
import com.minhtrung.hrm.leave.dtos.responses.LeavePreviewResponse;
import com.minhtrung.hrm.leave.dtos.responses.ManagerLeaveResponse;
import com.minhtrung.hrm.leave.dtos.responses.StaffLeaveResponse;
import com.minhtrung.hrm.leave.entities.LeaveRequest;
import com.minhtrung.hrm.leave.services.LeaveService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/leave")
@RequiredArgsConstructor
public class LeaveController {

    private final LeaveService leaveService;

    private UserRole getCurrentUserRole() {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return new UserRole(payload.getUserId(), payload.getDepartment(), payload.getJob());
    }

    // 0. Xem trước tính toán ngày nghỉ (Preview Leave Request)
    @GetMapping("/preview")
    public ResponseEntity<LeavePreviewResponse> previewLeaveRequest(
            @RequestParam LocalDate fromDate,
            @RequestParam LocalDate toDate) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(leaveService.previewLeaveRequest(userRole.getUserId(), fromDate, toDate));
    }

    // 1. Tạo đơn nghỉ phép
    @PostMapping
    public ResponseEntity<LeaveRequest> createLeaveRequest(@Valid @RequestBody CreateLeaveReqRequest request) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        request.setRequestorId(payload.getUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(leaveService.createLeaveRequest(request));
    }

    // 2. Xem đơn cá nhân của chính mình
    @GetMapping("/my-requests")
    public ResponseEntity<Page<StaffLeaveResponse>> getMyLeaveRequests(
            @ModelAttribute LeaveFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(leaveService.getMyLeaveRequests(userRole.getUserId(), filter, pageable));
    }

    // 3. Xem danh sách các đơn cần duyệt (Dành cho TP HR, TP IT, BGĐ...)
    @GetMapping("/approvals")
    public ResponseEntity<Page<ManagerLeaveResponse>> getLeaveRequestsToApprove(
            @ModelAttribute LeaveFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(leaveService.getLeaveRequestsToApprove(userRole, filter, pageable));
    }

    // 4. Xem toàn bộ đơn công ty (Dành riêng cho HR để theo dõi/chấm công)
    @GetMapping("/company")
    public ResponseEntity<Page<HrLeaveResponse>> getCompanyLeaveRequests(
            @ModelAttribute LeaveFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(leaveService.getCompanyLeaveRequests(userRole, filter, pageable));
    }

    // 5. Duyệt đơn
    @PatchMapping("/{requestId}/handle")
    public ResponseEntity<LeaveRequest> handleLeaveRequest(
            @PathVariable UUID requestId,
            @Valid @RequestBody HandleLeaveReqApiRequest request) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(leaveService.handleLeaveRequest(requestId, request, userRole));
    }

    // 6. Hủy / Xóa đơn xin nghỉ phép (Chỉ được xóa đơn của chính mình khi đang ở trạng thái pending)
    @DeleteMapping("/{requestId}")
    public ResponseEntity<Map<String, String>> cancelLeaveRequest(@PathVariable UUID requestId) {
        UserRole userRole = getCurrentUserRole();
        leaveService.cancelLeaveRequest(requestId, userRole.getUserId());
        return ResponseEntity.ok(Map.of("message", "Đơn xin nghỉ phép đã được hủy thành công"));
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportLeaveRequestsToExcel(@ModelAttribute LeaveFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = leaveService.exportLeaveRequestsToExcel(userRole, filter);

        String fileName = "leave_report_" + System.currentTimeMillis() + ".xlsx";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(
                        MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

}