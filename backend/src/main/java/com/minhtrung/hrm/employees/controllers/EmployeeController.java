package com.minhtrung.hrm.employees.controllers;

import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.requests.CreateEmployeeRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateAssignmentRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateBasicInfoRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateLegalProfileRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdatePayrollRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateProfileRequest;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDetailResponse;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDirectoryItemResponse;
import com.minhtrung.hrm.employees.dtos.responses.EmployeePublicProfile;
import com.minhtrung.hrm.employees.services.EmployeeService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
@Slf4j
public class EmployeeController {

    private final EmployeeService employeeService;

    /**
     * API 0: Lấy danh sách danh bạ nhân viên (Tìm kiếm đa năng, lọc theo phòng ban & phân trang).
     * 
     * GET /api/employees?keyword=...&department=...&page=0&size=10
     */
    @GetMapping
    public ResponseEntity<Page<EmployeeDirectoryItemResponse>> getEmployeeDirectory(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String department,
            @PageableDefault(size = 10, sort = "employeeCode", direction = Sort.Direction.ASC) Pageable pageable
    ) {
        log.info("Fetching employee directory. Keyword: {}, Department: {}, Page: {}", 
                keyword, department, pageable.getPageNumber());
        Page<EmployeeDirectoryItemResponse> directoryPage = employeeService.getEmployeeDirectory(keyword, department, pageable);
        return ResponseEntity.ok(directoryPage);
    }

    /**
     * API 1: Lấy thông tin hồ sơ công khai của một nhân viên (Trang chính & Danh bạ công ty).
     * 
     * GET /api/employees/{userId}/public-profile
     */
    @GetMapping("/{userId}/public-profile")
    public ResponseEntity<EmployeePublicProfile> getEmployeePublicProfile(@PathVariable UUID userId) {
        log.info("Fetching public profile for employee ID: {}", userId);
        EmployeePublicProfile profile = employeeService.getEmployeePublicProfile(userId);
        return ResponseEntity.ok(profile);
    }

    /**
     * API 2: Lấy thông tin hồ sơ chi tiết trọn gói (Fetch 1 lần toàn bộ các Tab có phân quyền tự động).
     * 
     * GET /api/employees/{userId}/detailed
     */
    @GetMapping("/{userId}/detailed")
    public ResponseEntity<EmployeeDetailResponse> getEmployeeDetailedProfile(@PathVariable UUID userId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} is fetching detailed profile for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.getEmployeeDetailedProfile(userId, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 3: Lấy thông tin hồ sơ chi tiết trọn gói của chính người đang đăng nhập.
     * 
     * GET /api/employees/me/detailed
     */
    @GetMapping("/me/detailed")
    public ResponseEntity<EmployeeDetailResponse> getMyDetailedProfile() {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("Fetching full personal profile for current user: {}", currentUser.getUserId());

        EmployeeDetailResponse response = employeeService.getEmployeeDetailedProfile(currentUser.getUserId(), currentUser);
        return ResponseEntity.ok(response);
    }

    // ─── CÁC API CẬP NHẬT DÀNH CHO NHÂN SỰ (HR UPDATE ENDPOINTS) ────

    /**
     * API 4.1: Cập nhật thông tin cơ bản ở Header / Trang chính (users + phoneNumber).
     * Chỉ HR hoặc Executive mới có quyền gọi.
     * 
     * PUT /api/employees/{userId}/basic-info
     */
    @PutMapping("/{userId}/basic-info")
    public ResponseEntity<EmployeeDetailResponse> updateBasicInfo(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateBasicInfoRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating basic info for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.updateBasicInfo(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 4.2: Cập nhật hồ sơ pháp lý & nhân thân ở Tab 1 (user_profiles).
     * Chỉ HR hoặc Executive mới có quyền gọi.
     * 
     * PUT /api/employees/{userId}/legal-profile
     */
    @PutMapping("/{userId}/legal-profile")
    public ResponseEntity<EmployeeDetailResponse> updateLegalProfile(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateLegalProfileRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating legal profile for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.updateLegalProfile(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 4: Cập nhật thông tin cơ bản & pháp lý gộp chung (tương thích ngược).
     * Chỉ HR hoặc Executive mới có quyền gọi.
     * 
     * PUT /api/employees/{userId}/profile
     */
    @PutMapping("/{userId}/profile")
    public ResponseEntity<EmployeeDetailResponse> updateProfile(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateProfileRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating profile for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.updateProfile(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 5: Cập nhật / Tái ký hợp đồng lao động (Tab 2: user_contracts).
     * Chỉ HR hoặc Executive mới có quyền gọi.
     * 
     * PUT /api/employees/{userId}/contract
     */
    @PutMapping("/{userId}/contract")
    public ResponseEntity<EmployeeDetailResponse> updateContract(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateContractRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating contract for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.updateContract(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 6: Điều chỉnh Lương & Tài khoản ngân hàng (Tab 3: salaries & user_bank_accounts).
     * Chỉ HR hoặc Executive mới có quyền gọi.
     * 
     * PUT /api/employees/{userId}/payroll
     */
    @PutMapping("/{userId}/payroll")
    public ResponseEntity<EmployeeDetailResponse> updatePayroll(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdatePayrollRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating payroll for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.updatePayroll(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 7: Điều chuyển công tác (Phòng ban, Chức vụ, Ca làm việc).
     * Chỉ HR hoặc Executive mới có quyền gọi.
     * 
     * PUT /api/employees/{userId}/assignment
     */
    @PutMapping("/{userId}/assignment")
    public ResponseEntity<EmployeeDetailResponse> updateAssignment(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateAssignmentRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating assignment for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.updateAssignment(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 8: Tạo nhân viên mới trọn gói (Dành riêng cho HR).
     * 
     * POST /api/employees
     */
    @PostMapping
    public ResponseEntity<EmployeeDetailResponse> createEmployee(
            @Valid @RequestBody CreateEmployeeRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} creating new employee with email: {}", currentUser.getUserId(), request.getEmail());

        EmployeeDetailResponse response = employeeService.createEmployee(request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
