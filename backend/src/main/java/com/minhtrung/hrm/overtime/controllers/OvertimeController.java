package com.minhtrung.hrm.overtime.controllers;

import java.util.Map;
import java.util.UUID;

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
import com.minhtrung.hrm.overtime.dtos.requests.HandleOvertimeReqApiRequest;
import com.minhtrung.hrm.overtime.dtos.requests.OvertimeFilterRequest;
import com.minhtrung.hrm.overtime.dtos.requests.OvertimeWorkTimeRequest;
import com.minhtrung.hrm.overtime.dtos.responses.HrOvertimeResponse;
import com.minhtrung.hrm.overtime.dtos.responses.ManagerOvertimeResponse;
import com.minhtrung.hrm.overtime.dtos.responses.StaffOvertimeResponse;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.services.OvertimeService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/overtime")
@RequiredArgsConstructor
public class OvertimeController {

    private final OvertimeService overtimeService;

    // Helper trích xuất UserRole từ Request Context
    private UserRole getCurrentUserRole() {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return new UserRole(payload.getUserId(), payload.getDepartment(), payload.getJob());
    }

    @PutMapping("/{userId}")
    public ResponseEntity<Map<String, String>> updateAttendance(@PathVariable UUID userId) {
        String action = overtimeService.checkOTAttenndance(userId);

        return ResponseEntity.status(200).body(Map.of(
            "action", action,
            "msg", "Check attendance completed"));
    }

    /**
     * 1. Tạo đơn làm thêm giờ
     * POST /api/overtime
     */
    @PostMapping
    public ResponseEntity<OvertimeRecord> createOvertimeRequest(@Valid @RequestBody OvertimeWorkTimeRequest request) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(overtimeService.createOvertimeRequest(payload.getUserId(), request));
    }

    /**
     * 1b. Hủy đơn làm thêm giờ (khi đang pending)
     * DELETE /api/overtime/{overtimeRecordId}
     */
    @DeleteMapping("/{overtimeRecordId}")
    public ResponseEntity<Map<String, String>> cancelOvertimeRequest(@PathVariable UUID overtimeRecordId) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        overtimeService.cancelOvertimeRequest(payload.getUserId(), overtimeRecordId);
        return ResponseEntity.ok(Map.of("msg", "Đã hủy đơn làm thêm giờ thành công"));
    }

    /**
     * 2. Xem danh sách đơn OT của cá nhân
     * GET /api/overtime/my-records
     */
    @GetMapping("/my-records")
    public ResponseEntity<Page<StaffOvertimeResponse>> getMyOvertimeRecords(
            @ModelAttribute OvertimeFilterRequest filter,
            @PageableDefault(size = 20, sort = "approvedDate", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(overtimeService.getMyOvertimeRecords(userRole.getUserId(), filter, pageable));
    }

    /**
     * 3. Xem danh sách đơn OT cần duyệt (Dành cho TP HR, TP IT, BGĐ...)
     * GET /api/overtime/approvals
     */
    @GetMapping("/approvals")
    public ResponseEntity<Page<ManagerOvertimeResponse>> getOvertimeRecordsToApprove(
            @ModelAttribute OvertimeFilterRequest filter,
            @PageableDefault(size = 20, sort = "approvedDate", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(overtimeService.getOvertimeRecordsToApprove(userRole, filter, pageable));
    }

    /**
     * 4. Xem toàn bộ đơn OT công ty (Chỉ dành riêng cho phòng HR)
     * GET /api/overtime/company
     */
    @GetMapping("/company")
    public ResponseEntity<Page<HrOvertimeResponse>> getCompanyOvertimeRecords(
            @ModelAttribute OvertimeFilterRequest filter,
            @PageableDefault(size = 20, sort = "approvedDate", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(overtimeService.getCompanyOvertimeRecords(userRole, filter, pageable));
    }

    /**
     * 5. Xuất file Excel báo cáo OT (Chỉ dành riêng cho phòng HR)
     * GET /api/overtime/export
     */
    @GetMapping("/export")
    public ResponseEntity<byte[]> exportOvertimeToExcel(@ModelAttribute OvertimeFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = overtimeService.exportOvertimeToExcel(userRole, filter);

        String fileName = "overtime_report_" + System.currentTimeMillis() + ".xlsx";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    /**
     * 6. Duyệt / Từ chối đơn làm thêm giờ
     * PATCH /api/overtime/{overtimeRecordId}/handle
     */
    @PatchMapping("/{overtimeRecordId}/handle")
    public ResponseEntity<OvertimeRecord> handleOvertimeRequest(
            @PathVariable UUID overtimeRecordId,
            @Valid @RequestBody HandleOvertimeReqApiRequest request) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(overtimeService.handleOvertimeRequest(overtimeRecordId, request, userRole));
    }
}