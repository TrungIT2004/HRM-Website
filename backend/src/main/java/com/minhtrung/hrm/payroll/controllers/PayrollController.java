package com.minhtrung.hrm.payroll.controllers;

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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
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
import com.minhtrung.hrm.payroll.dtos.requests.CompanyPayrollFilterRequest;
import com.minhtrung.hrm.payroll.dtos.requests.EditPayrollRequest;
import com.minhtrung.hrm.payroll.dtos.requests.StaffPayrollFilterRequest;
import com.minhtrung.hrm.payroll.dtos.responses.CompanyPayrollResponse;
import com.minhtrung.hrm.payroll.dtos.responses.MonthlyPayrollSummaryResponse;
import com.minhtrung.hrm.payroll.dtos.responses.StaffPayrollResponse;
import com.minhtrung.hrm.payroll.services.PayrollService;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/payrolls")
@Slf4j
public class PayrollController {

    private final PayrollService payrollService;

    public PayrollController(PayrollService payrollService) {
        this.payrollService = payrollService;
    }

    private UserRole getCurrentUserRole() {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return new UserRole(payload.getUserId(), payload.getDepartment(), payload.getJob());
    }

    // =========================================================================
    // 1. CÁ NHÂN: XEM PHIẾU LƯƠNG & XUẤT EXCEL
    // =========================================================================

    /**
     * Tất cả nhân viên đều có thể xem danh sách phiếu lương của chính mình (bao gồm cả DRAFT để đối soát)
     */
    @GetMapping("/me")
    public ResponseEntity<Page<StaffPayrollResponse>> getMyPayrolls(
            @ModelAttribute StaffPayrollFilterRequest filter,
            @PageableDefault(size = 12, sort = "periodMonth", direction = Sort.Direction.DESC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.getMyPayrolls(userRole.getUserId(), filter, pageable));
    }

    /**
     * Xuất Excel phiếu lương cá nhân
     */
    @GetMapping("/me/export")
    public ResponseEntity<byte[]> exportMyPayrollsToExcel(
            @ModelAttribute StaffPayrollFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = payrollService.exportMyPayrollsToExcel(userRole.getUserId(), filter);

        String fileName = String.format("my_payroll_report_%s.xlsx", System.currentTimeMillis());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    // =========================================================================
    // 2. TOÀN CÔNG TY: DÀNH RIÊNG CHO KẾ TOÁN & BAN GIÁM ĐỐC
    // =========================================================================

    /**
     * Kế toán và Ban Giám Đốc xem bảng lương toàn bộ nhân viên (tự động loại trừ chính mình)
     */
    @GetMapping("/company")
    public ResponseEntity<Page<CompanyPayrollResponse>> getCompanyPayrolls(
            @ModelAttribute CompanyPayrollFilterRequest filter,
            @PageableDefault(size = 20, sort = "user.employeeCode", direction = Sort.Direction.ASC) Pageable pageable) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.getCompanyPayrolls(userRole, filter, pageable));
    }

    /**
     * Xuất Excel bảng lương toàn công ty
     */
    @GetMapping("/company/export")
    public ResponseEntity<byte[]> exportCompanyPayrollsToExcel(
            @ModelAttribute CompanyPayrollFilterRequest filter) {
        UserRole userRole = getCurrentUserRole();
        byte[] excelBytes = payrollService.exportCompanyPayrollsToExcel(userRole, filter);

        String fileName = String.format("company_payroll_report_%s.xlsx", System.currentTimeMillis());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    /**
     * Xem tổng hợp chi phí lương và bảo hiểm công ty cho 1 tháng cụ thể
     */
    @GetMapping("/summary")
    public ResponseEntity<MonthlyPayrollSummaryResponse> getMonthlyPayrollSummary(
            @RequestParam int month,
            @RequestParam int year) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.getMonthlyPayrollSummary(month, year, userRole));
    }

    // =========================================================================
    // 3. TÍNH TOÁN, ĐIỀU CHỈNH, PHÊ DUYỆT & CHI TRẢ
    // =========================================================================

    /**
     * Kế toán kích hoạt tính toán bảng lương tự động từ MonthlyTimesheet (LOCKED)
     * Cho phép tính toán lại nếu kỳ lương đang ở trạng thái DRAFT.
     * {@code filter} giữ nguyên bộ lọc đang xem (từ khoá, phòng ban) để phạm vi
     * tính toán khớp với những dòng người dùng đang nhìn thấy trên bảng.
     */
    @PostMapping("/generate")
    public ResponseEntity<Map<String, Object>> generatePayroll(
            @RequestParam int month,
            @RequestParam int year,
            @ModelAttribute CompanyPayrollFilterRequest filter,
            @RequestParam(required = false) List<UUID> userIds) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.generatePayroll(month, year, userRole, filter, userIds));
    }

    /**
     * Kế toán điều chỉnh phụ cấp, thưởng, khấu trừ khác khi bảng lương ở trạng thái DRAFT
     */
    @PutMapping("/{payrollId}")
    public ResponseEntity<CompanyPayrollResponse> editPayroll(
            @PathVariable UUID payrollId,
            @Valid @RequestBody EditPayrollRequest request) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.editPayroll(payrollId, request, userRole));
    }

    /**
     * Kế toán trưởng phê duyệt bảng lương tháng (chuyển sang APPROVED)
     */
    @PutMapping("/approve")
    public ResponseEntity<Map<String, Object>> approvePayroll(
            @RequestParam int month,
            @RequestParam int year) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.approvePayroll(month, year, userRole));
    }

    /**
     * Kế toán xác nhận hoàn tất chi trả bảng lương tháng (chuyển sang PAID)
     */
    @PutMapping("/pay")
    public ResponseEntity<Map<String, Object>> markAsPaid(
            @RequestParam int month,
            @RequestParam int year) {
        UserRole userRole = getCurrentUserRole();
        return ResponseEntity.ok(payrollService.markAsPaid(month, year, userRole));
    }
}
