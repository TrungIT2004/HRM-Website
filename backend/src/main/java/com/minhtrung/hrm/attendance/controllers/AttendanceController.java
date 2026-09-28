package com.minhtrung.hrm.attendance.controllers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.attendance.dtos.requests.AttendanceFilterRequest;
import com.minhtrung.hrm.attendance.dtos.requests.CompanyTimesheetFilterRequest;
import com.minhtrung.hrm.attendance.dtos.requests.EditAttendanceRequest;
import com.minhtrung.hrm.attendance.dtos.requests.ManagerTimesheetFilterRequest;
import com.minhtrung.hrm.attendance.dtos.requests.MonthlyTimesheetEditRequest;
import com.minhtrung.hrm.attendance.dtos.requests.StaffTimesheetFilterRequest;
import com.minhtrung.hrm.attendance.dtos.response.CompanyMonthlyTimesheetResponse;
import com.minhtrung.hrm.attendance.dtos.response.HrAttendanceResponse;
import com.minhtrung.hrm.attendance.dtos.response.ManagerAttendanceResponse;
import com.minhtrung.hrm.attendance.dtos.response.StaffAttendanceResponse;
import com.minhtrung.hrm.attendance.dtos.response.StaffMonthlyTimesheetResponse;
import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.services.AttendanceService;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;



@RestController
@RequestMapping("/api/attendances")
@Slf4j
public class AttendanceController {
    private final AttendanceService attendanceService;

    public AttendanceController(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    private UserRole getCurrentUserRole() {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return new UserRole(payload.getUserId(), payload.getDepartment(), payload.getJob());
    }

    // 1. Chấm công cá nhân
    @GetMapping("/my-attendances")
    public ResponseEntity<Page<StaffAttendanceResponse>> getMyAttendances(
            @ModelAttribute AttendanceFilterRequest filter,
            @PageableDefault(size = 20, sort = "workDate", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.getMyAttendances(userRole.getUserId(), filter, pageable));
    }

    // 2. Chấm công quản lý (Trưởng phòng/BGĐ)
    @GetMapping("/department")
    public ResponseEntity<Page<ManagerAttendanceResponse>> getDepartmentAttendances(
            @ModelAttribute AttendanceFilterRequest filter,
            @PageableDefault(size = 20, sort = "workDate", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.getDepartmentAttendances(userRole, filter, pageable));
    }

    // 3. Chấm công toàn công ty (Dành riêng cho HR)
    @GetMapping("/company")
    public ResponseEntity<Page<HrAttendanceResponse>> getCompanyAttendances(
            @ModelAttribute AttendanceFilterRequest filter,
            @PageableDefault(size = 20, sort = "workDate", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.getCompanyAttendances(userRole, filter, pageable));
    }

    @PutMapping("/{userId}")
    public ResponseEntity<Map<String, String>> updateAttendance(@PathVariable UUID userId) {
        String action = attendanceService.checkAttendance(userId);

        return ResponseEntity.status(200).body(Map.of(
            "action", action,
            "msg", "Check attendance completed"));
    }
    
    @PutMapping("/edit/{attendanceId}")
    public ResponseEntity<Map<String, Object>> editEmployeeAttendanceRecord(@PathVariable UUID attendanceId,
            @Valid @RequestBody EditAttendanceRequest request) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        UUID userId = payload.getUserId();
        String department = payload.getDepartment();
        String job = payload.getJob();

        UserRole userRole = new UserRole(userId, department, job);

        Attendance editedAttendance = attendanceService.editAttendanceRecord(attendanceId, userRole, request);
        return ResponseEntity.status(200).body(Map.of(
            "msg", "Attendance record updated successfully",
            "attendanceId", editedAttendance.getAttendanceId(),
            "status", editedAttendance.getStatus()
        ));
    }

    @DeleteMapping("/{attendanceId}")
    public ResponseEntity<String> deleteEmployeeAttendanceRecord(@PathVariable UUID attendanceId) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        UUID userId = payload.getUserId();
        String department = payload.getDepartment();
        String job = payload.getJob();

        UserRole userRole = new UserRole(userId, department, job);
        attendanceService.deleteAttendanceRecord(attendanceId, userRole);
        return ResponseEntity.status(200).body("Attendance Record deleted");
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportAttendancesToExcel(@ModelAttribute AttendanceFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = attendanceService.exportAttendancesToExcel(userRole, filter);

        String fileName = "attendance_report_" + System.currentTimeMillis() + ".xlsx";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    // ==========================================
    // MONTHLY TIMESHEET SUMMARY ENDPOINTS
    // ==========================================

    // 1. Cá nhân xem bảng công của chính mình
    @GetMapping("/summary/me")
    public ResponseEntity<Page<StaffMonthlyTimesheetResponse>> getMyMonthlySummary(
            @ModelAttribute StaffTimesheetFilterRequest filter,
            @PageableDefault(size = 12, sort = "periodMonth", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.getMyMonthlyTimesheets(userRole.getUserId(), filter, pageable));
    }

    // Xuất Excel bảng công cá nhân
    @GetMapping("/summary/me/export")
    public ResponseEntity<byte[]> exportMyMonthlySummaryToExcel(
            @ModelAttribute StaffTimesheetFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = attendanceService.exportMyMonthlyTimesheetsToExcel(userRole.getUserId(), filter);

        String fileName = String.format("my_monthly_timesheet_%s.xlsx", System.currentTimeMillis());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    // 2. Trưởng phòng xem bảng công phòng ban (chừa chính mình ra)
    @GetMapping("/summary/department")
    public ResponseEntity<Page<CompanyMonthlyTimesheetResponse>> getDepartmentMonthlySummary(
            @ModelAttribute ManagerTimesheetFilterRequest filter,
            @PageableDefault(size = 20, sort = "user.employeeCode", direction = Sort.Direction.ASC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.getDepartmentMonthlyTimesheets(userRole, filter, pageable));
    }

    // Xuất Excel bảng công phòng ban (Trưởng phòng)
    @GetMapping("/summary/department/export")
    public ResponseEntity<byte[]> exportDepartmentMonthlySummaryToExcel(
            @ModelAttribute ManagerTimesheetFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = attendanceService.exportDepartmentMonthlyTimesheetsToExcel(userRole, filter);

        String fileName = String.format("department_timesheet_report_%s.xlsx", System.currentTimeMillis());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    // 3. HR / Executive xem bảng công toàn công ty (chừa chính mình ra)
    @GetMapping("/summary/company")
    public ResponseEntity<Page<CompanyMonthlyTimesheetResponse>> getCompanyMonthlySummary(
            @ModelAttribute CompanyTimesheetFilterRequest filter,
            @PageableDefault(size = 20, sort = "user.employeeCode", direction = Sort.Direction.ASC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.getCompanyMonthlyTimesheets(userRole, filter, pageable));
    }

    // Xuất Excel bảng công toàn công ty (HR / Executive)
    @GetMapping("/summary/company/export")
    public ResponseEntity<byte[]> exportCompanyMonthlySummaryToExcel(
            @ModelAttribute CompanyTimesheetFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = attendanceService.exportCompanyMonthlyTimesheetsToExcel(userRole, filter);

        String fileName = String.format("company_timesheet_report_%s.xlsx", System.currentTimeMillis());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    // 4. HR / Executive kích hoạt tính toán bảng chấm công tháng (cho phép re-generate khi DRAFT)
    @PostMapping("/summary/generate")
    public ResponseEntity<Map<String, Object>> generateMonthlySummary(
            @RequestParam int month,
            @RequestParam int year) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.generateMonthlyTimesheets(month, year, userRole));
    }

    // 5. HR / Executive điều chỉnh chi tiết công khi ở trạng thái DRAFT
    @PutMapping("/summary/{timesheetId}")
    public ResponseEntity<CompanyMonthlyTimesheetResponse> editMonthlyTimesheet(
            @PathVariable UUID timesheetId,
            @Valid @RequestBody MonthlyTimesheetEditRequest request) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.editMonthlyTimesheet(timesheetId, request, userRole));
    }

    // 6. Trưởng phòng HR / Ban Giám Đốc chốt sổ bảng công tháng (LOCKED)
    // userIds rỗng = chốt cả tháng; có giá trị = chỉ chốt nhóm nhân viên đang tick trên bảng.
    @PutMapping("/summary/lock")
    public ResponseEntity<Map<String, Object>> lockMonthlySummary(
            @RequestParam int month,
            @RequestParam int year,
            @RequestParam(required = false) List<UUID> userIds) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(attendanceService.lockMonthlyTimesheet(month, year, userRole, userIds));
    }
}
