package com.minhtrung.hrm.employees.services;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
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
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftScheduleRepository;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.employees.dtos.internals.UserDetailedInfo;
import com.minhtrung.hrm.employees.dtos.requests.CreateEmployeeRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateAssignmentRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateBasicInfoRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateContractRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateLegalProfileRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdatePayrollRequest;
import com.minhtrung.hrm.employees.dtos.requests.UpdateProfileRequest;
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
import com.minhtrung.hrm.employees.enums.PayFrequency;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.JobRepository;
import com.minhtrung.hrm.employees.repositories.SalaryRepository;
import com.minhtrung.hrm.employees.repositories.UserBankAccountRepository;
import com.minhtrung.hrm.employees.repositories.UserContractRepository;
import com.minhtrung.hrm.employees.repositories.UserProfileRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;

@Service
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
    private final PasswordEncoder passwordEncoder;

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
            PasswordEncoder passwordEncoder
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
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * 0. LẤY DANH SÁCH DANH BẠ NHÂN VIÊN (Tìm kiếm, lọc theo phòng ban & phân trang).
     * Chỉ trả về đúng 6 trường tối giản.
     */
    @Transactional(readOnly = true)
    public Page<EmployeeDirectoryItemResponse> getEmployeeDirectory(String keyword, String department, Pageable pageable) {
        Page<User> usersPage = userRepository.findUsersByDepartmentAndKeyword(department, keyword, pageable);
        return usersPage.map(user -> EmployeeDirectoryItemResponse.builder()
                .userId(user.getUserId())
                .employeeCode(user.getEmployeeCode())
                .fullName(user.getFirstName() + " " + user.getLastName())
                .profilePicUrl(user.getProfilePicUrl())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .jobTitle(user.getJob() != null ? user.getJob().getTitle() : null)
                .build());
    }

    /**
     * 1. LẤY HỒ SƠ CÔNG KHAI (Trang chính & Danh bạ công ty - Ai cũng xem được).
     */
    @Transactional(readOnly = true)
    public EmployeePublicProfile getEmployeePublicProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + userId));

        // 1.1 Trạng thái chấm công hôm nay
        LocalDate today = LocalDate.now();
        Optional<Attendance> todayAttendance = attendanceRepository.findUsersTodayAttendance(userId, today);
        String todayStatus = todayAttendance
                .map(att -> att.getStatus().name())
                .orElse("NOT_CHECKED");

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
                .shiftName(shiftName)
                .weeklySchedule(weeklySchedule)
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

        boolean isSameDeptHead = currentUser.getJob() != null 
                && currentUser.getJob().startsWith("Department Head")
                && targetUser.getDepartment() != null 
                && targetUser.getDepartment().getName().equalsIgnoreCase(currentUser.getDepartment());

        // 2.1 Khối công khai (Ai cũng xem được)
        EmployeePublicProfile publicProfile = getEmployeePublicProfile(targetUserId);

        // 2.2 Tab 1: Định danh & Pháp lý (Chỉ Me + HR/Giám đốc)
        LegalProfileDto legalProfile = null;
        if (isMe || isHR || isExecutive) {
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
        if (isMe || isSameDeptHead || isHR || isExecutive) {
            UserContract c = targetUser.getContract();
            if (c != null) {
                contract = ContractDto.builder()
                        .contractType(c.getContractType())
                        .contractStartDate(c.getContractStartDate())
                        .contractEndDate(c.getContractEndDate())
                        .probationEndDate(c.getProbationEndDate())
                        .build();
            }
        }

        // 2.4 Tab 3: Lương & Ngân hàng (Chỉ Me + HR/Giám đốc - Trưởng phòng bị ẩn null)
        PayrollDto payroll = null;
        if (isMe || isHR || isExecutive) {
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
        checkHRAccess(currentUser);

        User user = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        UserContract contract = userContractRepository.findById(targetUserId).orElseGet(() -> {
            UserContract c = new UserContract();
            c.setUser(user);
            return c;
        });

        if (request.getContractType() != null) contract.setContractType(request.getContractType().trim());
        if (request.getContractStartDate() != null) contract.setContractStartDate(request.getContractStartDate());
        if (request.getContractEndDate() != null) contract.setContractEndDate(request.getContractEndDate());
        if (request.getProbationEndDate() != null) contract.setProbationEndDate(request.getProbationEndDate());

        userContractRepository.save(contract);

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
     * HR Tạo tài khoản và hồ sơ nhân viên mới trọn gói.
     */
    @Transactional
    public EmployeeDetailResponse createEmployee(CreateEmployeeRequest request, TokenPayload currentUser) {
        checkHRAccess(currentUser);

        if (userRepository.existsByEmail(request.getEmail().trim())) {
            throw new IllegalArgumentException("Email " + request.getEmail() + " đã tồn tại trên hệ thống!");
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
            shift = workShiftRepository.findAll().stream().findFirst()
                    .orElseThrow(() -> new IllegalStateException("Chưa cấu hình ca làm việc mặc định trong hệ thống"));
        }

        String employeeCode = request.getEmployeeCode();
        if (employeeCode == null || employeeCode.isBlank()) {
            Long nextNumber = userRepository.getNextEmployeeNumber();
            employeeCode = "EMP" + String.format("%03d", nextNumber);
        }

        User user = new User();
        user.setEmail(request.getEmail().trim());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName().trim());
        user.setLastName(request.getLastName().trim());
        user.setGender(request.getGender() != null ? request.getGender() : "Nam");
        user.setBirthDate(request.getBirthDate() != null ? request.getBirthDate() : LocalDate.of(1995, 1, 1));
        user.setJoinedDate(request.getJoinedDate() != null ? request.getJoinedDate() : LocalDate.now());
        user.setProfilePicUrl(request.getProfilePicUrl() != null && !request.getProfilePicUrl().isBlank()
                ? request.getProfilePicUrl() : "https://ui-avatars.com/api/?name=" + request.getFirstName() + "+" + request.getLastName() + "&background=random");
        user.setAnnualLeaveDays(12);
        user.setUsedLeaveDays(0);
        user.setEmployeeCode(employeeCode);
        user.setDepartment(department);
        user.setJob(job);
        user.setShift(shift);

        User savedUser = userRepository.save(user);

        // Khởi tạo UserProfile
        UserProfile profile = new UserProfile();
        profile.setUser(savedUser);
        if (request.getPhoneNumber() != null) profile.setPhoneNumber(request.getPhoneNumber().trim());
        if (request.getCitizenId() != null) profile.setCitizenIdNumber(request.getCitizenId().trim());
        if (request.getAddress() != null) profile.setPlaceOfBirth(request.getAddress().trim());
        userProfileRepository.save(profile);

        // Khởi tạo UserContract
        UserContract contract = new UserContract();
        contract.setUser(savedUser);
        contract.setContractType("Hợp đồng xác định thời hạn");
        contract.setContractStartDate(savedUser.getJoinedDate());
        contract.setContractEndDate(savedUser.getJoinedDate().plusYears(1));
        userContractRepository.save(contract);

        // Khởi tạo Salary ban đầu nếu có baseSalary
        if (request.getBaseSalary() != null) {
            Salary salary = new Salary();
            salary.setUser(savedUser);
            salary.setBaseSalary(request.getBaseSalary().doubleValue());
            salary.setPayFrequency(PayFrequency.MONTHLY);
            salary.setWorkDays(22.0);
            salary.setStartDate(savedUser.getJoinedDate());
            salary.setActive(true);
            salaryRepository.save(salary);
        }

        // Gửi email chào mừng kèm thông tin tài khoản & mật khẩu tạm (Tạm thời comment do email hiện tại là fake)
        // emailService.sendWelcomeEmail(savedUser.getEmail(), savedUser.getFirstName(), request.getPassword());

        return getEmployeeDetailedProfile(savedUser.getUserId(), currentUser);
    }

    // ─── 4. HELPER METHODS ──────────────────────────────────────────

    /**
     * Kiểm tra người gọi có phải là HR hay không (Chỉ DUY NHẤT HR mới được quyền chỉnh sửa).
     * Ban Giám Đốc chỉ có quyền xem (View-all), không trực tiếp chỉnh sửa dữ liệu tác vụ.
     */
    private void checkHRAccess(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        if (!isHR) {
            throw new AccessDeniedException("Chỉ có phòng Nhân Sự (Human Resources) mới có quyền điều chỉnh hồ sơ nhân viên!");
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
}
