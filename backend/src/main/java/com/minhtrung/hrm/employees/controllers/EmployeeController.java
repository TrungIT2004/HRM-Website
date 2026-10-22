package com.minhtrung.hrm.employees.controllers;

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
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.requests.CreateContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.CreateEmployeeRequest;
import com.minhtrung.hrm.employees.dtos.requests.RenewContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateAssignmentRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateBasicInfoRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateEmployeeStatusRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateLegalProfileRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdatePayrollRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateProfileRequest;
import com.minhtrung.hrm.employees.dtos.responses.AvatarUploadResponse;
import com.minhtrung.hrm.employees.dtos.responses.ContractResponse;
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
     * API 5.1: Lấy toàn bộ lịch sử hợp đồng của nhân viên.
     * GET /api/employees/{userId}/contracts
     */
    @GetMapping("/{userId}/contracts")
    public ResponseEntity<java.util.List<ContractResponse>> getContractHistory(@PathVariable UUID userId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        java.util.List<ContractResponse> history = employeeService.getContractHistory(userId, currentUser);
        return ResponseEntity.ok(history);
    }

    /**
     * API 5.2: Gia hạn hợp đồng lao động (Tạo HĐ mới, đóng HĐ cũ).
     * POST /api/employees/{userId}/contracts/renew
     */
    @PostMapping("/{userId}/contracts/renew")
    public ResponseEntity<EmployeeDetailResponse> renewContract(
            @PathVariable UUID userId,
            @Valid @RequestBody RenewContractRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} renewing contract for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.renewContract(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 5.3: Ký hợp đồng lao động mới.
     * POST /api/employees/{userId}/contracts
     */
    @PostMapping("/{userId}/contracts")
    public ResponseEntity<EmployeeDetailResponse> createContract(
            @PathVariable UUID userId,
            @Valid @RequestBody CreateContractRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} creating new contract for employee ID: {}", currentUser.getUserId(), userId);

        EmployeeDetailResponse response = employeeService.createContract(userId, request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * API 5.4: Chỉnh sửa 1 hợp đồng cụ thể (sửa lỗi chính tả/ngày tháng).
     * PUT /api/employees/{userId}/contracts/{contractId}
     */
    @PutMapping("/{userId}/contracts/{contractId}")
    public ResponseEntity<EmployeeDetailResponse> updateSpecificContract(
            @PathVariable UUID userId,
            @PathVariable UUID contractId,
            @Valid @RequestBody UpdateContractRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("HR user {} updating specific contract {} for employee ID: {}", currentUser.getUserId(), contractId, userId);

        EmployeeDetailResponse response = employeeService.updateSpecificContract(userId, contractId, request, currentUser);
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

    /**
     * API 9: Khóa hoặc Mở khóa tài khoản nhân viên thôi việc (Chỉ dành cho HR Head hoặc Executive).
     * 
     * PATCH /api/employees/{userId}/status
     */
    @PatchMapping("/{userId}/status")
    public ResponseEntity<EmployeeDetailResponse> updateEmployeeStatus(
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateEmployeeStatusRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} updating status for employee {}: isActive={}", currentUser.getUserId(), userId, request.getIsActive());

        EmployeeDetailResponse response = employeeService.updateEmployeeStatus(userId, request, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 10: Nhân viên tự upload / cập nhật ảnh đại diện (Avatar) của chính mình.
     * 
     * POST /api/employees/me/avatar
     */
    @PostMapping("/me/avatar")
    public ResponseEntity<AvatarUploadResponse> updateMyAvatar(
            @RequestParam("file") MultipartFile file
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("Current user {} is uploading their avatar", currentUser.getUserId());

        AvatarUploadResponse response = employeeService.updateAvatar(currentUser.getUserId(), file, currentUser);
        return ResponseEntity.ok(response);
    }

    /**
     * API 11: HR / Ban Giám Đốc upload ảnh đại diện cho nhân viên bất kỳ.
     * 
     * POST /api/employees/{userId}/avatar
     */
    @PostMapping("/{userId}/avatar")
    public ResponseEntity<AvatarUploadResponse> updateEmployeeAvatar(
            @PathVariable UUID userId,
            @RequestParam("file") MultipartFile file
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} is uploading avatar for employee {}", currentUser.getUserId(), userId);

        AvatarUploadResponse response = employeeService.updateAvatar(userId, file, currentUser);
        return ResponseEntity.ok(response);
    }
}
