package com.minhtrung.hrm.attendance.controllers;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.attendance.dtos.requests.CreateWorkShiftRequest;
import com.minhtrung.hrm.attendance.dtos.response.WorkShiftResponse;
import com.minhtrung.hrm.attendance.services.WorkShiftService;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/work-shifts")
@RequiredArgsConstructor
@Slf4j
public class WorkShiftController {

    private final WorkShiftService workShiftService;

    /**
     * Lấy toàn bộ danh sách các ca làm việc trong hệ thống (dùng cho dropdown chọn ca & hiển thị lịch).
     * 
     * GET /api/work-shifts
     */
    @GetMapping
    public ResponseEntity<List<WorkShiftResponse>> getAllWorkShifts() {
        return ResponseEntity.ok(workShiftService.getAllWorkShifts());
    }

    /**
     * Ca làm việc của chính nhân viên đang đăng nhập. Trả 404 nếu chưa được phân ca.
     *
     * GET /api/work-shifts/my-shift
     */
    @GetMapping("/my-shift")
    public ResponseEntity<WorkShiftResponse> getMyWorkShift() {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(workShiftService.getMyWorkShift(currentUser.getUserId()));
    }

    /**
     * Tạo ca làm việc mới kèm lịch 7 ngày trong tuần.
     * Chỉ Trưởng phòng HR hoặc Ban Giám Đốc mới có quyền tạo.
     * 
     * POST /api/work-shifts
     */
    @PostMapping
    public ResponseEntity<WorkShiftResponse> createWorkShift(@Valid @RequestBody CreateWorkShiftRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} is creating work shift: {}", currentUser.getUserId(), request.getName());

        WorkShiftResponse createdShift = workShiftService.createWorkShift(request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdShift);
    }

    /**
     * Cập nhật tên ca + lịch 7 ngày. Vẫn kiểm tra luật &lt;= 8h/ngày và &lt;= 48h/tuần.
     * PUT /api/work-shifts/{shiftId}
     */
    @PutMapping("/{shiftId}")
    public ResponseEntity<WorkShiftResponse> updateWorkShift(
            @PathVariable UUID shiftId,
            @Valid @RequestBody CreateWorkShiftRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(workShiftService.updateWorkShift(shiftId, request, currentUser));
    }

    /**
     * Xoá ca làm việc. Trả 409 nếu còn nhân viên dùng ca hoặc đã có lịch sử chấm công.
     * DELETE /api/work-shifts/{shiftId}
     */
    @DeleteMapping("/{shiftId}")
    public ResponseEntity<Map<String, String>> deleteWorkShift(@PathVariable UUID shiftId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        workShiftService.deleteWorkShift(shiftId, currentUser);
        return ResponseEntity.ok(Map.of("message", "Đã xoá ca làm việc thành công"));
    }
}
