package com.minhtrung.hrm.employees.services;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.attendance.entities.WorkShiftSchedule;
import com.minhtrung.hrm.attendance.repositories.AttendanceRepository;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;
import com.minhtrung.hrm.overtime.repositories.OvertimeRecordRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftScheduleRepository;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.employees.dtos.internals.UserDetailedInfo;
import com.minhtrung.hrm.employees.dtos.requests.CreateContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.CreateEmployeeRequest;
import com.minhtrung.hrm.employees.dtos.requests.RenewContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateAssignmentRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateBasicInfoRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateLegalProfileRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdatePayrollRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateProfileRequest;
import com.minhtrung.hrm.employees.dtos.responses.ContractResponse;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDetailResponse;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDetailResponse.ContractDto;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDetailResponse.LegalProfileDto;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDetailResponse.PayrollDto;
import com.minhtrung.hrm.employees.dtos.responses.EmployeeDirectoryItemResponse;
import com.minhtrung.hrm.employees.dtos.responses.EmployeePublicProfile;
import com.minhtrung.hrm.employees.dtos.responses.EmployeePublicProfile.WorkShiftScheduleDto;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.employees.entities.Salary;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.entities.UserBankAccount;
import com.minhtrung.hrm.employees.entities.UserContract;
import com.minhtrung.hrm.employees.entities.UserProfile;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.auth.entities.PendingUser;
import com.minhtrung.hrm.auth.repositories.PendingUserRepository;
import com.minhtrung.hrm.auth.entities.UserSession;
import com.minhtrung.hrm.auth.repositories.UserSessionRepository;
import com.minhtrung.hrm.auth.services.SessionBlacklistService;
import com.minhtrung.hrm.services.FileStorageService;
import com.minhtrung.hrm.employees.dtos.requests.UpdateEmployeeStatusRequest;
import com.minhtrung.hrm.employees.dtos.responses.AvatarUploadResponse;
import com.minhtrung.hrm.employees.enums.PayFrequency;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.JobRepository;
import com.minhtrung.hrm.employees.repositories.SalaryRepository;
import com.minhtrung.hrm.employees.repositories.UserBankAccountRepository;
import com.minhtrung.hrm.employees.repositories.UserContractRepository;
import com.minhtrung.hrm.employees.repositories.UserProfileRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class EmployeeService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserContractRepository userContractRepository;
    private final UserBankAccountRepository userBankAccountRepository;
    private final SalaryRepository salaryRepository;
    private final DepartmentRepository departmentRepository;
    private final JobRepository jobRepository;
    private final WorkShiftRepository workShiftRepository;
    private final WorkShiftScheduleRepository workShiftScheduleRepository;
    private final AttendanceRepository attendanceRepository;
    private final OvertimeRecordRepository overtimeRecordRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserSessionRepository userSessionRepository;
    private final SessionBlacklistService sessionBlacklistService;
    private final FileStorageService fileStorageService;
    private final PendingUserRepository pendingUserRepository;
    private final PermissionService permissionService;

    // Dependency Injection qua Constructor
    public EmployeeService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            UserContractRepository userContractRepository,
            UserBankAccountRepository userBankAccountRepository,
            SalaryRepository salaryRepository,
            DepartmentRepository departmentRepository,
            JobRepository jobRepository,
            WorkShiftRepository workShiftRepository,
            WorkShiftScheduleRepository workShiftScheduleRepository,
            AttendanceRepository attendanceRepository,
            OvertimeRecordRepository overtimeRecordRepository,
            PasswordEncoder passwordEncoder,
            UserSessionRepository userSessionRepository,
            SessionBlacklistService sessionBlacklistService,
            FileStorageService fileStorageService,
            PendingUserRepository pendingUserRepository,
            PermissionService permissionService
    ) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.userContractRepository = userContractRepository;
        this.userBankAccountRepository = userBankAccountRepository;
        this.salaryRepository = salaryRepository;
        this.departmentRepository = departmentRepository;
        this.jobRepository = jobRepository;
        this.workShiftRepository = workShiftRepository;
        this.workShiftScheduleRepository = workShiftScheduleRepository;
        this.attendanceRepository = attendanceRepository;
        this.overtimeRecordRepository = overtimeRecordRepository;
        this.passwordEncoder = passwordEncoder;
        this.userSessionRepository = userSessionRepository;
        this.sessionBlacklistService = sessionBlacklistService;
        this.fileStorageService = fileStorageService;
        this.pendingUserRepository = pendingUserRepository;
        this.permissionService = permissionService;
    }

    /**
     * 0. LẤY DANH SÁCH DANH BẠ NHÂN VIÊN (Tìm kiếm, lọc theo phòng ban & phân trang).
     * Trạng thái hôm nay lấy bằng 2 query batch cho cả trang (không N+1).
     */
    @Transactional(readOnly = true)
    public Page<EmployeeDirectoryItemResponse> getEmployeeDirectory(String keyword, String department, Pageable pageable) {
        Page<User> usersPage = userRepository.findUsersByDepartmentAndKeyword(department, keyword, pageable);
        List<UUID> ids = usersPage.getContent().stream().map(User::getUserId).toList();

        LocalDate today = LocalDate.now();
        Map<UUID, String> statusByUser = resolveTodayStatuses(ids, today);
        Map<UUID, String> otByUser = resolveTodayOvertime(ids, today);

        return usersPage.map(user -> EmployeeDirectoryItemResponse.builder()
                .userId(user.getUserId())
                .employeeCode(user.getEmployeeCode())
                .fullName(user.getFirstName() + " " + user.getLastName())
                .profilePicUrl(user.getProfilePicUrl())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .jobTitle(user.getJob() != null ? user.getJob().getTitle() : null)
                .isActive(user.isActive())
                .todayStatus(statusByUser.getOrDefault(user.getUserId(), "DAY_OFF"))
                .todayOvertimeStatus(otByUser.get(user.getUserId()))
                .build());
    }

    /**
     * Trạng thái chấm công hôm nay theo user.
     * Không có bản ghi = "DAY_OFF" (nghỉ) vì cron chỉ tạo record cho ngày làm việc.
     */
    private Map<UUID, String> resolveTodayStatuses(List<UUID> userIds, LocalDate today) {
        if (userIds.isEmpty()) return Map.of();
        Map<UUID, String> result = new HashMap<>();
        for (Attendance att : attendanceRepository.findAttendancesByUserIdsAndDateRange(
                userIds, today, today)) {
            result.put(att.getUser().getUserId(),
                    att.getStatus() != null ? att.getStatus().name() : "NOT_CHECKED");
        }
        return result;
    }

    /** "OVERTIMING" = đã quẹt vào OT nhưng chưa ra; "OVERTIME_DONE" = đã có cả hai mốc. */
    private Map<UUID, String> resolveTodayOvertime(List<UUID> userIds, LocalDate today) {
        if (userIds.isEmpty()) return Map.of();
        Map<UUID, String> result = new HashMap<>();
        for (OvertimeRecord ot : overtimeRecordRepository
                .findByRequestor_UserIdInAndApprovedDateAndStatus(userIds, today, OvertimeRecordStatus.accepted)) {
            if (ot.getRequestor() == null) continue;
            boolean started = ot.getClockInTime() != null;
            boolean finished = ot.getClockOutTime() != null;
            String state = (started && finished) ? "OVERTIME_DONE" : started ? "OVERTIMING" : "NONE";
            result.put(ot.getRequestor().getUserId(), state);
        }
        return result;
    }

    /**
     * 1. LẤY HỒ SƠ CÔNG KHAI (Trang chính & Danh bạ công ty - Ai cũng xem được).
     */
    @Transactional(readOnly = true)
    public EmployeePublicProfile getEmployeePublicProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + userId));

        // 1.1 Trạng thái chấm công hôm nay + tăng ca hôm nay
        LocalDate today = LocalDate.now();
        UUID uid = user.getUserId();
        // Không có bản ghi = "DAY_OFF" (nghỉ) vì cron chỉ tạo record cho ngày làm việc.
        String todayStatus = resolveTodayStatuses(List.of(uid), today).getOrDefault(uid, "DAY_OFF");
        String todayOvertimeStatus = resolveTodayOvertime(List.of(uid), today).get(uid);

        // 1.2 Lịch làm việc 7 ngày từ work_shift_schedules
        WorkShift shift = user.getShift();
        String shiftName = (shift != null) ? shift.getName() : "Chưa phân ca";
        List<WorkShiftScheduleDto> weeklySchedule = List.of();

        if (shift != null) {
            List<WorkShiftSchedule> schedules = workShiftScheduleRepository.findByWorkShift_ShiftId(shift.getShiftId());
            weeklySchedule = schedules.stream()
                    .sorted(Comparator.comparing(WorkShiftSchedule::getDayOfWeek))
                    .map(s -> WorkShiftScheduleDto.builder()
                            .dayOfWeek(s.getDayOfWeek())
                            .dayName(mapDayOfWeekToVietnameseName(s.getDayOfWeek()))
                            .isWorking(s.isWorking())
                            .startTime(s.getStartTime())
                            .endTime(s.getEndTime())
                            .restStartTime(s.getRestStartTime())
                            .restEndTime(s.getRestEndTime())
                            .build())
                    .toList();
        }

        return EmployeePublicProfile.builder()
                .userId(user.getUserId())
                .employeeCode(user.getEmployeeCode())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .fullName(user.getFirstName() + " " + user.getLastName())
                .profilePicUrl(user.getProfilePicUrl())
                .gender(user.getGender())
                .birthDate(user.getBirthDate())
                .joinedDate(user.getJoinedDate())
                .jobTitle(user.getJob() != null ? user.getJob().getTitle() : null)
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .workEmail(user.getEmail())
                .phoneNumber(user.getProfile() != null ? user.getProfile().getPhoneNumber() : null)
                .todayStatus(todayStatus)
                .todayOvertimeStatus(todayOvertimeStatus)
                .shiftName(shiftName)
                .weeklySchedule(weeklySchedule)
                .isActive(user.isActive())
                .build();
    }

    /**
     * 2. LẤY HỒ SƠ CHI TIẾT TRỌN GÓI (FETCH 1 LẦN TẤT CẢ CÁC TAB CÓ PHÂN QUYỀN TỰ ĐỘNG).
     */
    @Transactional(readOnly = true)
    public EmployeeDetailResponse getEmployeeDetailedProfile(UUID targetUserId, TokenPayload currentUser) {
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        // Phân cấp quyền hạn:
        boolean isMe = currentUser.getUserId().equals(targetUserId);
        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());
        // EMPLOYEE_VIEW_ALL tách riêng EMPLOYEE_EDIT vì các tab dưới đây chứa dữ liệu nhạy cảm
        // (lương, số tài khoản, CCCD) — có thể cấp cho người chỉ cần xem, không cần sửa.
        boolean canViewAllProfile = isHR || isExecutive
                || permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_VIEW_ALL);

        boolean isSameDeptHead = currentUser.getJob() != null 
                && currentUser.getJob().startsWith("Department Head")
                && targetUser.getDepartment() != null 
                && targetUser.getDepartment().getName().equalsIgnoreCase(currentUser.getDepartment());

        // 2.1 Khối công khai (Ai cũng xem được)
        EmployeePublicProfile publicProfile = getEmployeePublicProfile(targetUserId);

        // 2.2 Tab 1: Định danh & Pháp lý (Chỉ Me + HR/Giám đốc)
        LegalProfileDto legalProfile = null;
        if (isMe || canViewAllProfile) {
            UserProfile p = targetUser.getProfile();
            if (p != null) {
                legalProfile = LegalProfileDto.builder()
                        .citizenIdNumber(p.getCitizenIdNumber())
                        .taxIdentificationNumber(p.getTaxIdentificationNumber())
                        .socialInsuranceNumber(p.getSocialInsuranceNumber())
                        .socialInsuranceStartDate(p.getSocialInsuranceStartDate())
                        .personalEmail(p.getPersonalEmail())
                        .placeOfBirth(p.getPlaceOfBirth())
                        .maritalStatus(p.getMaritalStatus())
                        .nationality(p.getNationality())
                        .emergencyContactName(p.getEmergencyContactName())
                        .emergencyContactPhone(p.getEmergencyContactPhone())
                        .build();
            }
        }

        // 2.3 Tab 2: Hợp đồng lao động (Me + Trưởng phòng cùng team + HR/Giám đốc)
        ContractDto contract = null;
        List<ContractDto> contracts = null;
        if (isMe || isSameDeptHead || canViewAllProfile) {
            List<UserContract> allContracts = userContractRepository.findByUser_UserIdOrderByContractStartDateDesc(targetUserId);
            contracts = allContracts.stream()
                    .map(c -> ContractDto.builder()
                            .contractId(c.getContractId())
                            .contractType(c.getContractType())
                            .contractStartDate(c.getContractStartDate())
                            .contractEndDate(c.getContractEndDate())
                            .isActive(c.isActive())
                            .build())
                    .toList();

            UserContract activeContract = allContracts.stream()
                    .filter(UserContract::isActive)
                    .findFirst()
                    .orElse(allContracts.isEmpty() ? null : allContracts.get(0));

            if (activeContract != null) {
                contract = ContractDto.builder()
                        .contractId(activeContract.getContractId())
                        .contractType(activeContract.getContractType())
                        .contractStartDate(activeContract.getContractStartDate())
                        .contractEndDate(activeContract.getContractEndDate())
                        .isActive(activeContract.isActive())
                        .build();
            }
        }

        // 2.4 Tab 3: Lương & Ngân hàng (Chỉ Me + HR/Giám đốc - Trưởng phòng bị ẩn null)
        PayrollDto payroll = null;
        if (isMe || canViewAllProfile) {
            Optional<Salary> salaryOpt = salaryRepository.findByUser_UserIdAndIsActiveTrue(targetUserId)
                    .or(() -> salaryRepository.findByUser_UserId(targetUserId));

            UserBankAccount b = targetUser.getBankAccount();

            payroll = PayrollDto.builder()
                    .baseSalary(salaryOpt.map(s -> Math.round(s.getBaseSalary())).orElse(null))
                    .payFrequency(salaryOpt.map(s -> s.getPayFrequency() != null ? s.getPayFrequency().name() : null).orElse(null))
                    .workDays(salaryOpt.map(Salary::getWorkDays).orElse(null))
                    .startDate(salaryOpt.map(Salary::getStartDate).orElse(null))
                    .endDate(salaryOpt.map(Salary::getEndDate).orElse(null))
                    .isActive(salaryOpt.map(Salary::isActive).orElse(null))
                    .bankName(b != null ? b.getBankName() : null)
                    .bankAccountNumber(b != null ? b.getBankAccountNumber() : null)
                    .build();
        }

        return EmployeeDetailResponse.builder()
                .publicProfile(publicProfile)
                .legalProfile(legalProfile)
                .contract(contract)
                .contracts(contracts)
                .payroll(payroll)
                .build();
    }

    // ─── 3. CÁC HÀM CẬP NHẬT THÔNG TIN DÀNH CHO NHÂN SỰ (HR UPDATE APIS) ────

    /**
     * 3.1 Cập nhật thông tin cơ bản ở Header / Trang chính (users + phoneNumber).
     */
    @Transactional
    public EmployeeDetailResponse updateBasicInfo(UUID targetUserId, UpdateBasicInfoRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        if (request.getFirstName() != null && !request.getFirstName().isBlank()) {
            user.setFirstName(request.getFirstName().trim());
        }
        if (request.getLastName() != null && !request.getLastName().isBlank()) {
            user.setLastName(request.getLastName().trim());
        }
        if (request.getGender() != null) {
            user.setGender(request.getGender());
        }
        if (request.getBirthDate() != null) {
            user.setBirthDate(request.getBirthDate());
        }
        if (request.getProfilePicUrl() != null) {
            user.setProfilePicUrl(request.getProfilePicUrl());
        }
        userRepository.save(user);

        if (request.getPhoneNumber() != null) {
            UserProfile profile = userProfileRepository.findById(targetUserId).orElseGet(() -> {
                UserProfile p = new UserProfile();
                p.setUser(user);
                return p;
            });
            profile.setPhoneNumber(request.getPhoneNumber().trim());
            userProfileRepository.save(profile);
        }

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * 3.2 Cập nhật hồ sơ pháp lý & nhân thân ở Tab 1 (user_profiles).
     */
    @Transactional
    public EmployeeDetailResponse updateLegalProfile(UUID targetUserId, UpdateLegalProfileRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        UserProfile profile = userProfileRepository.findById(targetUserId).orElseGet(() -> {
            UserProfile p = new UserProfile();
            p.setUser(user);
            return p;
        });

        if (request.getCitizenIdNumber() != null) profile.setCitizenIdNumber(request.getCitizenIdNumber().trim());
        if (request.getTaxIdentificationNumber() != null) profile.setTaxIdentificationNumber(request.getTaxIdentificationNumber().trim());
        if (request.getSocialInsuranceNumber() != null) profile.setSocialInsuranceNumber(request.getSocialInsuranceNumber().trim());
        if (request.getSocialInsuranceStartDate() != null) profile.setSocialInsuranceStartDate(request.getSocialInsuranceStartDate());
        if (request.getPersonalEmail() != null) profile.setPersonalEmail(request.getPersonalEmail().trim());
        if (request.getPlaceOfBirth() != null) profile.setPlaceOfBirth(request.getPlaceOfBirth().trim());
        if (request.getMaritalStatus() != null) profile.setMaritalStatus(request.getMaritalStatus().trim());
        if (request.getNationality() != null) profile.setNationality(request.getNationality().trim());
        if (request.getEmergencyContactName() != null) profile.setEmergencyContactName(request.getEmergencyContactName().trim());
        if (request.getEmergencyContactPhone() != null) profile.setEmergencyContactPhone(request.getEmergencyContactPhone().trim());

        userProfileRepository.save(profile);

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Cập nhật thông tin cơ bản & pháp lý gộp chung (tương thích ngược)
     */
    @Transactional
    public EmployeeDetailResponse updateProfile(UUID targetUserId, UpdateProfileRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        // Cập nhật thông tin bảng users
        if (request.getFirstName() != null && !request.getFirstName().isBlank()) {
            user.setFirstName(request.getFirstName().trim());
        }
        if (request.getLastName() != null && !request.getLastName().isBlank()) {
            user.setLastName(request.getLastName().trim());
        }
        if (request.getGender() != null) {
            user.setGender(request.getGender());
        }
        if (request.getBirthDate() != null) {
            user.setBirthDate(request.getBirthDate());
        }
        if (request.getProfilePicUrl() != null) {
            user.setProfilePicUrl(request.getProfilePicUrl());
        }
        userRepository.save(user);

        // Cập nhật thông tin bảng user_profiles
        UserProfile profile = userProfileRepository.findById(targetUserId).orElseGet(() -> {
            UserProfile p = new UserProfile();
            p.setUser(user);
            return p;
        });

        if (request.getPhoneNumber() != null) profile.setPhoneNumber(request.getPhoneNumber().trim());
        if (request.getPersonalEmail() != null) profile.setPersonalEmail(request.getPersonalEmail().trim());
        if (request.getPlaceOfBirth() != null) profile.setPlaceOfBirth(request.getPlaceOfBirth().trim());
        if (request.getMaritalStatus() != null) profile.setMaritalStatus(request.getMaritalStatus().trim());
        if (request.getNationality() != null) profile.setNationality(request.getNationality().trim());
        if (request.getCitizenIdNumber() != null) profile.setCitizenIdNumber(request.getCitizenIdNumber().trim());
        if (request.getSocialInsuranceNumber() != null) profile.setSocialInsuranceNumber(request.getSocialInsuranceNumber().trim());
        if (request.getSocialInsuranceStartDate() != null) profile.setSocialInsuranceStartDate(request.getSocialInsuranceStartDate());
        if (request.getTaxIdentificationNumber() != null) profile.setTaxIdentificationNumber(request.getTaxIdentificationNumber().trim());
        if (request.getEmergencyContactName() != null) profile.setEmergencyContactName(request.getEmergencyContactName().trim());
        if (request.getEmergencyContactPhone() != null) profile.setEmergencyContactPhone(request.getEmergencyContactPhone().trim());

        userProfileRepository.save(profile);

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Cập nhật thông tin hợp đồng lao động (Tab 2: user_contracts)
     */
    @Transactional
    public EmployeeDetailResponse updateContract(UUID targetUserId, UpdateContractRequest request, TokenPayload currentUser) {
        checkContractEditAllowed(targetUserId, currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        UserContract contract = userContractRepository.findByUser_UserId(targetUserId).orElseGet(() -> {
            UserContract c = new UserContract();
            c.setUser(user);
            return c;
        });

        if (request.getContractType() != null) contract.setContractType(request.getContractType().trim());
        if (request.getContractStartDate() != null) contract.setContractStartDate(request.getContractStartDate());
        if (request.getContractEndDate() != null) contract.setContractEndDate(request.getContractEndDate());

        userContractRepository.save(contract);

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Gia hạn hợp đồng lao động:
     * - Chuyển tất cả hợp đồng đang active thành active = false
     * - Tạo record hợp đồng mới với is_active = true
     */
    @Transactional
    public EmployeeDetailResponse renewContract(UUID targetUserId, RenewContractRequest request, TokenPayload currentUser) {
        checkContractEditAllowed(targetUserId, currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        // Đóng tất cả hợp đồng đang active hiện tại
        List<UserContract> activeContracts = userContractRepository.findByUser_UserIdAndIsActiveTrue(targetUserId);
        for (UserContract oldContract : activeContracts) {
            oldContract.setActive(false);
            userContractRepository.save(oldContract);
        }

        // Tạo hợp đồng mới
        UserContract newContract = new UserContract();
        newContract.setUser(user);
        newContract.setContractType(request.getContractType().trim());
        newContract.setContractStartDate(request.getContractStartDate());
        newContract.setContractEndDate(request.getContractEndDate());
        newContract.setActive(true);
        userContractRepository.save(newContract);

        log.info("HR {} đã gia hạn hợp đồng cho nhân viên {}. Loại: {}, Bắt đầu: {}, Kết thúc: {}",
                currentUser.getUserId(), targetUserId, request.getContractType(), request.getContractStartDate(), request.getContractEndDate());

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Ký hợp đồng mới (Create New Contract)
     */
    @Transactional
    public EmployeeDetailResponse createContract(UUID targetUserId, CreateContractRequest request, TokenPayload currentUser) {
        checkContractEditAllowed(targetUserId, currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        // Đóng tất cả hợp đồng đang active hiện tại
        List<UserContract> activeContracts = userContractRepository.findByUser_UserIdAndIsActiveTrue(targetUserId);
        for (UserContract oldContract : activeContracts) {
            oldContract.setActive(false);
            userContractRepository.save(oldContract);
        }

        // Tạo hợp đồng mới
        UserContract newContract = new UserContract();
        newContract.setUser(user);
        newContract.setContractType(request.getContractType().trim());
        newContract.setContractStartDate(request.getContractStartDate());
        newContract.setContractEndDate(request.getContractEndDate());
        newContract.setActive(true);
        userContractRepository.save(newContract);

        log.info("HR {} đã tạo hợp đồng mới cho nhân viên {}. Loại: {}, Bắt đầu: {}",
                currentUser.getUserId(), targetUserId, request.getContractType(), request.getContractStartDate());

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Lấy toàn bộ lịch sử hợp đồng của nhân viên
     */
    @Transactional(readOnly = true)
    public List<ContractResponse> getContractHistory(UUID targetUserId, TokenPayload currentUser) {
        boolean isMe = currentUser != null && targetUserId.equals(currentUser.getUserId());
        boolean isHR = currentUser != null && "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        boolean isExecutive = currentUser != null && "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());
        boolean canViewAllProfile = isHR || isExecutive
                || (currentUser != null && permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_VIEW_ALL));

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        boolean isSameDeptHead = currentUser != null 
                && currentUser.getJob() != null 
                && currentUser.getJob().startsWith("Department Head")
                && targetUser.getDepartment() != null
                && targetUser.getDepartment().getName().equalsIgnoreCase(currentUser.getDepartment());

        if (!isMe && !isSameDeptHead && !canViewAllProfile) {
            throw new AccessDeniedException("Bạn không có quyền xem lịch sử hợp đồng của nhân viên này!");
        }

        return userContractRepository.findByUser_UserIdOrderByContractStartDateDesc(targetUserId).stream()
                .map(c -> ContractResponse.builder()
                        .contractId(c.getContractId())
                        .userId(targetUserId)
                        .contractType(c.getContractType())
                        .contractStartDate(c.getContractStartDate())
                        .contractEndDate(c.getContractEndDate())
                        .isActive(c.isActive())
                        .build())
                .toList();
    }

    /**
     * Sửa thông tin 1 hợp đồng cụ thể (sửa lỗi chính tả / ngày tháng)
     */
    @Transactional
    public EmployeeDetailResponse updateSpecificContract(UUID targetUserId, UUID contractId, UpdateContractRequest request, TokenPayload currentUser) {
        checkContractEditAllowed(targetUserId, currentUser);

        UserContract contract = userContractRepository.findById(contractId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hợp đồng với ID: " + contractId));

        if (!contract.getUser().getUserId().equals(targetUserId)) {
            throw new IllegalArgumentException("Hợp đồng này không thuộc về nhân viên chỉ định!");
        }

        if (request.getContractType() != null && !request.getContractType().isBlank()) {
            contract.setContractType(request.getContractType().trim());
        }
        if (request.getContractStartDate() != null) {
            contract.setContractStartDate(request.getContractStartDate());
        }
        if (request.getContractEndDate() != null) {
            contract.setContractEndDate(request.getContractEndDate());
        }

        userContractRepository.save(contract);
        log.info("HR {} đã chỉnh sửa hợp đồng {} của nhân viên {}", currentUser.getUserId(), contractId, targetUserId);

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Cập nhật thông tin Lương & Ngân hàng (Tab 3: salaries & user_bank_accounts)
     */
    @Transactional
    public EmployeeDetailResponse updatePayroll(UUID targetUserId, UpdatePayrollRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        // Cập nhật bảng salaries
        Salary salary = salaryRepository.findByUser_UserId(targetUserId).orElseGet(() -> {
            Salary s = new Salary();
            s.setUser(user);
            s.setPayFrequency(PayFrequency.MONTHLY);
            s.setWorkDays(22.0);
            s.setStartDate(LocalDate.now());
            s.setActive(true);
            return s;
        });

        if (request.getBaseSalary() != null) salary.setBaseSalary(request.getBaseSalary().doubleValue());
        if (request.getPayFrequency() != null) {
            try {
                salary.setPayFrequency(PayFrequency.valueOf(request.getPayFrequency().trim().toUpperCase()));
            } catch (IllegalArgumentException ignored) {}
        }
        if (request.getWorkDays() != null) salary.setWorkDays(request.getWorkDays());
        if (request.getStartDate() != null) salary.setStartDate(request.getStartDate());
        if (request.getEndDate() != null) salary.setEndDate(request.getEndDate());
        if (request.getIsActive() != null) salary.setActive(request.getIsActive());

        salaryRepository.save(salary);

        // Cập nhật bảng user_bank_accounts
        UserBankAccount bank = userBankAccountRepository.findById(targetUserId).orElseGet(() -> {
            UserBankAccount b = new UserBankAccount();
            b.setUser(user);
            return b;
        });

        if (request.getBankName() != null) bank.setBankName(request.getBankName().trim());
        if (request.getBankAccountNumber() != null) bank.setBankAccountNumber(request.getBankAccountNumber().trim());

        userBankAccountRepository.save(bank);

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Điều chuyển công tác (Đổi phòng ban, chức danh, ca làm việc)
     */
    @Transactional
    public EmployeeDetailResponse updateAssignment(UUID targetUserId, UpdateAssignmentRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        if (request.getDepartmentId() != null) {
            Department dept = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new IllegalArgumentException("Phòng ban không tồn tại: " + request.getDepartmentId()));
            user.setDepartment(dept);
        }

        if (request.getJobId() != null) {
            Job job = jobRepository.findById(request.getJobId())
                    .orElseThrow(() -> new IllegalArgumentException("Vị trí công việc không tồn tại: " + request.getJobId()));
            user.setJob(job);
        }

        if (request.getShiftId() != null) {
            WorkShift shift = workShiftRepository.findById(request.getShiftId())
                    .orElseThrow(() -> new IllegalArgumentException("Ca làm việc không tồn tại: " + request.getShiftId()));
            user.setShift(shift);
        }

        userRepository.save(user);

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * HR Tạo hồ sơ Onboarding nhân viên mới (lưu vào pending_users chờ Admin cấp tài khoản).
     */
    @Transactional
    public EmployeeDetailResponse createEmployee(CreateEmployeeRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        String email = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";
        if (userRepository.existsByEmail(email) || pendingUserRepository.existsByPersonalEmail(email)) {
            throw new IllegalArgumentException("Email " + email + " đã tồn tại trên hệ thống hoặc đang chờ duyệt!");
        }

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new IllegalArgumentException("Phòng ban không tồn tại: " + request.getDepartmentId()));

        Job job = jobRepository.findById(request.getJobId())
                .orElseThrow(() -> new IllegalArgumentException("Vị trí công việc không tồn tại: " + request.getJobId()));

        WorkShift shift;
        if (request.getShiftId() != null) {
            shift = workShiftRepository.findById(request.getShiftId())
                    .orElseThrow(() -> new IllegalArgumentException("Ca làm việc không tồn tại: " + request.getShiftId()));
        } else {
            shift = workShiftRepository.findAll().stream().findFirst().orElse(null);
        }

        User creator = currentUser != null ? userRepository.findById(currentUser.getUserId()).orElse(null) : null;
        LocalDate startDate = request.getJoinedDate() != null ? request.getJoinedDate() : LocalDate.now();

        PendingUser pending = PendingUser.builder()
                .firstName(request.getFirstName().trim())
                .lastName(request.getLastName().trim())
                .gender(request.getGender() != null ? request.getGender() : "Nam")
                .birthDate(request.getBirthDate() != null ? request.getBirthDate() : LocalDate.of(1995, 1, 1))
                .personalEmail(email)
                .phoneNumber(request.getPhoneNumber() != null ? request.getPhoneNumber().trim() : null)
                .citizenId(request.getCitizenId() != null ? request.getCitizenId().trim() : null)
                .placeOfBirth(request.getAddress() != null ? request.getAddress().trim() : null)
                .department(department)
                .job(job)
                .shift(shift)
                .baseSalary(request.getBaseSalary())
                .contractType("Fixed-term")
                .contractStartDate(startDate)
                .contractEndDate(startDate.plusYears(1))
                .status("PENDING")
                .createdBy(creator)
                .build();

        PendingUser saved = pendingUserRepository.save(pending);
        log.info("HR {} đã tạo hồ sơ Onboarding chờ Admin duyệt. PendingId: {}, Tên: {} {}",
                currentUser.getUserId(), saved.getPendingId(), saved.getFirstName(), saved.getLastName());

        EmployeePublicProfile publicProfile = EmployeePublicProfile.builder()
                .userId(saved.getPendingId())
                .fullName((saved.getFirstName() + " " + saved.getLastName()).trim())
                .workEmail(email + " (Đang chờ Admin cấp email công ty)")
                .departmentName(department.getName())
                .jobTitle(job.getTitle())
                .joinedDate(startDate)
                .isActive(false)
                .employeeCode("PENDING")
                .profilePicUrl("https://ui-avatars.com/api/?name=" + saved.getFirstName() + "+" + saved.getLastName() + "&background=random")
                .build();

        return EmployeeDetailResponse.builder()
                .publicProfile(publicProfile)
                .build();
    }

    // ─── 4. HELPER METHODS ──────────────────────────────────────────

    /**
     * Kiểm tra người gọi có phải là HR hay không (quyền gốc của EMPLOYEE_EDIT).
     * Ban Giám Đốc chỉ có quyền xem, không trực tiếp chỉnh sửa dữ liệu tác vụ.
     */
    private void checkHRAccess(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        boolean hasGrant = permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_EDIT);
        if (!isHR && !hasGrant) {
            throw new AccessDeniedException("Chỉ có phòng Nhân Sự (Human Resources) mới có quyền điều chỉnh hồ sơ nhân viên!");
        }
    }

    /** isSysAdmin theo đúng định nghĩa backend (IT + System Administrator). */
    private boolean isSysAdmin(TokenPayload currentUser) {
        if (currentUser == null) return false;
        boolean isIT = "Information Technology".equalsIgnoreCase(currentUser.getDepartment())
                || "IT".equalsIgnoreCase(currentUser.getDepartment());
        return isIT && currentUser.getJob() != null
                && (currentUser.getJob().contains("System Administrator") || currentUser.getJob().contains("Admin"));
    }

    /**
     * Phân nhiệm (SoD) cho user_contracts: HR được sửa HĐ của người khác,
     * nhưng không bao giờ được tự tạo/sửa/gia hạn HĐ của chính mình.
     */
    private void checkContractEditAllowed(UUID targetUserId, TokenPayload currentUser) {
        checkHRAccess(currentUser);
        if (targetUserId != null && targetUserId.equals(currentUser.getUserId())) {
            throw new AccessDeniedException("Vì nguyên tắc phân nhiệm, bạn không được tự tạo/sửa/gia hạn hợp đồng của chính mình. Hãy nhờ một nhân sự HR khác thực hiện!");
        }
    }

    private String mapDayOfWeekToVietnameseName(int dayOfWeek) {
        return switch (dayOfWeek) {
            case 1 -> "Thứ 2";
            case 2 -> "Thứ 3";
            case 3 -> "Thứ 4";
            case 4 -> "Thứ 5";
            case 5 -> "Thứ 6";
            case 6 -> "Thứ 7";
            case 7 -> "Chủ Nhật";
            default -> "Ngày " + dayOfWeek;
        };
    }

    public UserDetailedInfo getEmployeeDetailedInf(UUID userId) {
        return userRepository.getUsersDetailedInfo(userId);
    }

    /**
     * Khóa hoặc Mở khóa tài khoản nhân viên. Quyền gốc: System Administrator.
     * Có thể ủy quyền thêm qua grant ACCOUNT_LOCK (Ban Giám Đốc đã bị gỡ — không phải quản trị viên).
     * Khi khóa: Thu hồi toàn bộ phiên đăng nhập của nhân viên đó trong Redis & DB ngay lập tức.
     */
    @Transactional
    public EmployeeDetailResponse updateEmployeeStatus(UUID targetUserId, UpdateEmployeeStatusRequest request, TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        if (!isSysAdmin(currentUser)
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.ACCOUNT_LOCK)) {
            throw new AccessDeniedException("Chỉ Quản trị viên Hệ thống (System Administrator) mới có quyền khóa/mở khóa tài khoản!");
        }

        if (currentUser.getUserId().equals(targetUserId)) {
            throw new IllegalArgumentException("Không thể tự thay đổi trạng thái hoạt động của chính tài khoản mình đang đăng nhập!");
        }

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        boolean newStatus = Boolean.TRUE.equals(request.getIsActive());
        targetUser.setActive(newStatus);
        userRepository.save(targetUser);

        // Nếu vô hiệu hóa/thôi việc -> Thu hồi ngay lập tức toàn bộ phiên đăng nhập
        if (!newStatus) {
            List<UserSession> activeSessions = userSessionRepository.findByUserId(targetUserId);
            for (UserSession s : activeSessions) {
                s.setRevoked(true);
                userSessionRepository.save(s);
                sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
            }
            log.warn("HR {} đã khóa tài khoản của nhân viên {} ({}). Lý do: {}",
                    currentUser.getUserId(), targetUser.getUserId(), targetUser.getEmail(), request.getReason());
        } else {
            log.info("HR {} đã kích hoạt lại tài khoản của nhân viên {} ({})",
                    currentUser.getUserId(), targetUser.getUserId(), targetUser.getEmail());
        }

        return getEmployeeDetailedProfile(targetUserId, currentUser);
    }

    /**
     * Cập nhật ảnh đại diện Avatar cho nhân viên.
     * Người dùng có thể tự đổi avatar của chính mình, HR hoặc Executive có thể đổi cho nhân viên khác.
     */
    @Transactional
    public AvatarUploadResponse updateAvatar(UUID targetUserId, MultipartFile file, TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }

        boolean isSelf = currentUser.getUserId().equals(targetUserId);
        // ghi/chỉnh sửa dữ liệu → theo EMPLOYEE_EDIT, không phải VIEW
        if (!isSelf && !"Human Resources".equalsIgnoreCase(currentUser.getDepartment())
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_EDIT)) {
            throw new AccessDeniedException("Bạn không có quyền cập nhật ảnh đại diện của nhân viên khác!");
        }

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        String avatarUrl = fileStorageService.storeAvatar(file, targetUserId);
        targetUser.setProfilePicUrl(avatarUrl);
        userRepository.save(targetUser);

        log.info("Người dùng {} đã cập nhật ảnh đại diện cho nhân viên {}: {}",
                currentUser.getUserId(), targetUserId, avatarUrl);

        return AvatarUploadResponse.builder()
                .profilePicUrl(avatarUrl)
                .message("Cập nhật ảnh đại diện thành công!")
                .build();
    }
}
