package com.minhtrung.hrm.admin.services;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.admin.dtos.requests.AdminResetPasswordRequest;
import com.minhtrung.hrm.admin.dtos.requests.AdminUpdateStatusRequest;
import com.minhtrung.hrm.admin.dtos.requests.CreatePendingUserRequest;
import com.minhtrung.hrm.admin.dtos.requests.ProvisionAccountRequest;
import com.minhtrung.hrm.admin.dtos.requests.RejectPendingUserRequest;
import com.minhtrung.hrm.admin.dtos.responses.AdminAccountResponse;
import com.minhtrung.hrm.admin.dtos.responses.AdminSessionResponse;
import com.minhtrung.hrm.admin.dtos.responses.PendingUserResponse;
import com.minhtrung.hrm.admin.dtos.responses.UserPermissionResponse;
import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.auth.entities.PendingUser;
import com.minhtrung.hrm.auth.entities.UserSession;
import com.minhtrung.hrm.auth.repositories.PendingUserRepository;
import com.minhtrung.hrm.auth.repositories.UserSessionRepository;
import com.minhtrung.hrm.auth.services.SessionBlacklistService;
import com.minhtrung.hrm.employees.entities.Salary;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.entities.UserContract;
import com.minhtrung.hrm.employees.entities.UserProfile;
import com.minhtrung.hrm.employees.enums.PayFrequency;
import com.minhtrung.hrm.employees.repositories.SalaryRepository;
import com.minhtrung.hrm.employees.repositories.UserContractRepository;
import com.minhtrung.hrm.employees.repositories.UserProfileRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.permissions.entities.PermissionGrant;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.JobRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminService {

    private final PendingUserRepository pendingUserRepository;
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserContractRepository userContractRepository;
    private final SalaryRepository salaryRepository;
    private final UserSessionRepository userSessionRepository;
    private final SessionBlacklistService sessionBlacklistService;
    private final PasswordEncoder passwordEncoder;
    private final PermissionService permissionService;
    private final DepartmentRepository departmentRepository;
    private final JobRepository jobRepository;
    private final WorkShiftRepository workShiftRepository;

    /** IT + System Administrator — định nghĩa sysadmin duy nhất của hệ thống. */
    private boolean isSysAdmin(TokenPayload currentUser) {
        if (currentUser == null) return false;
        boolean isIT = "Information Technology".equalsIgnoreCase(currentUser.getDepartment())
                || "IT".equalsIgnoreCase(currentUser.getDepartment());
        if (!isIT || currentUser.getJob() == null) return false;
        String job = currentUser.getJob();
        // ponytail: SUPER_ADMIN là sysadmin gieo sẵn (so sánh hoa/thường — "SUPER_ADMIN".contains("Admin") là false)
        return job.contains("System Administrator") || job.contains("Admin")
                || job.equalsIgnoreCase("SUPER_ADMIN") || job.toLowerCase().contains("super admin");
    }

    private boolean isExecutive(TokenPayload currentUser) {
        return currentUser != null && "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());
    }

    /** Quyền phát quyền cho người khác: sysadmin, hoặc được cấp grant PERMISSION_GRANT. */
    public boolean hasPermissionGrant(TokenPayload currentUser) {
        return currentUser != null && (isSysAdmin(currentUser)
                || permissionService.hasPermission(currentUser.getUserId(), PermissionKey.PERMISSION_GRANT));
    }

    /**
     * Quyền "Tài khoản & Bảo Mật": xem danh sách tài khoản, khoá/mở khoá, xem & thu hồi phiên.
     * ACCOUNT_LOCK đã mang nghĩa khoá tài khoản (khoá = thu hồi toàn bộ phiên), nên người được cấp
     * key này cần cả bề mặt quản lý tài khoản + phiên, không chỉ một nút khoá.
     * KHÔNG gồm: duyệt tài khoản onboarding và cấp lại mật khẩu — hai việc đó vẫn gọi checkAdminAccess.
     */
    private boolean canManageAccounts(TokenPayload currentUser) {
        return currentUser != null && (isSysAdmin(currentUser) || isExecutive(currentUser)
                || permissionService.hasPermission(currentUser.getUserId(), PermissionKey.ACCOUNT_LOCK));
    }

    private void checkAccountManagementAccess(TokenPayload currentUser) {
        if (!canManageAccounts(currentUser)) {
            throw new AccessDeniedException(
                    "Bạn không có quyền quản lý tài khoản. Cần quyền \"Mở / khóa tài khoản nhân viên\" hoặc là quản trị viên hệ thống.");
        }
    }

    /**
     * Kiểm tra quyền System Admin (theo Hướng B: IT + System Administrator).
     * Người được cấp PERMISSION_GRANT / ACCOUNT_LOCK cũng qua được — khớp gate frontend
     * (canEnterAdmin) và đúng ý "SUPER_ADMIN + nhân viên được cấp".
     */
    public void checkAdminAccess(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác quản trị!");
        }
        if (!isSysAdmin(currentUser) && !isExecutive(currentUser)
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.PERMISSION_GRANT)
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.ACCOUNT_LOCK)) {
            throw new AccessDeniedException("Chỉ Quản trị viên Hệ thống (System Administrator) hoặc Ban Giám Đốc mới có quyền truy cập khu vực này!");
        }
    }

    /**
     * Quyền CẤP QUYỀN — cố ý KHÔNG gọi checkAdminAccess().
     * Lý do: vào được /admin không đồng nghĩa được phát quyền cho người khác, và ngược lại —
     * người được cấp PERMISSION_GRANT thường là trưởng phòng (không phải admin hệ thống) nên
     * checkAdminAccess sẽ chặn họ trước khi tới đây. Hai vùng quyền tách bạch:
     * phiên đăng nhập / duyệt tài khoản = checkAdminAccess, phân quyền = hàm này.
     */
    public void checkPermissionGrantAccess(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác quản trị!");
        }
        if (!hasPermissionGrant(currentUser)) {
            throw new AccessDeniedException("Bạn cần được cấp quyền \"Cấp quyền cho nhân viên khác\" để thực hiện thao tác này!");
        }
    }

    // ─── 1. ONBOARDING & CẤP TÀI KHOẢN (PROVISIONING) ────────────────

    /**
     * HR nhập hồ sơ nhân viên sắp vào làm (bước 1 của onboarding).
     * Quyền: phòng Human Resources, sysadmin, Ban Giám Đốc, hoặc được cấp EMPLOYEE_EDIT.
     */
    @Transactional
    public PendingUserResponse createPendingUser(CreatePendingUserRequest request, TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        if (!isHR && !isSysAdmin(currentUser) && !isExecutive(currentUser)
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_EDIT)) {
            throw new AccessDeniedException("Chỉ phòng Nhân sự (hoặc người được cấp quyền sửa hồ sơ) mới được tạo hồ sơ tuyển dụng!");
        }

        String personalEmail = request.getPersonalEmail().trim().toLowerCase();
        if (pendingUserRepository.findByPersonalEmail(personalEmail).isPresent()) {
            throw new IllegalArgumentException("Email cá nhân " + personalEmail + " đã có hồ sơ chờ duyệt!");
        }

        PendingUser pending = PendingUser.builder()
                .firstName(request.getFirstName().trim())
                .lastName(request.getLastName().trim())
                .gender(request.getGender())
                .birthDate(request.getBirthDate())
                .personalEmail(personalEmail)
                .phoneNumber(request.getPhoneNumber())
                .citizenId(request.getCitizenId())
                .placeOfBirth(request.getPlaceOfBirth())
                .department(departmentRepository.findById(request.getDepartmentId())
                        .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phòng ban!")))
                .job(jobRepository.findById(request.getJobId())
                        .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy chức danh!")))
                .shift(request.getShiftId() != null
                        ? workShiftRepository.findById(request.getShiftId()).orElse(null)
                        : null)
                .baseSalary(request.getBaseSalary())
                .contractType(request.getContractType())
                .contractStartDate(request.getContractStartDate())
                .contractEndDate(request.getContractEndDate())
                .status("PENDING")
                .build();
        // createdBy không có trong builder @AllArgsConstructor? gán trực tiếp cho chắc
        userRepository.findById(currentUser.getUserId()).ifPresent(pending::setCreatedBy);
        PendingUser saved = pendingUserRepository.save(pending);

        log.info("User {} đã tạo hồ sơ tuyển dụng {} ({} {})", currentUser.getUserId(),
                saved.getPendingId(), saved.getFirstName(), saved.getLastName());
        return mapToPendingResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<PendingUserResponse> getPendingUsers(TokenPayload currentUser, String status) {
        // Xem danh sach cho phep rong hon tao/duyet: HR duoc xem de theo doi ho so minh tao
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        if (!isHR && !isSysAdmin(currentUser) && !isExecutive(currentUser)
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_EDIT)
                && !permissionService.hasPermission(currentUser.getUserId(), PermissionKey.EMPLOYEE_VIEW_ALL)) {
            throw new AccessDeniedException("Bạn không có quyền xem hồ sơ tuyển dụng!");
        }
        String filterStatus = (status != null && !status.isBlank()) ? status.toUpperCase() : "PENDING";

        return pendingUserRepository.findByStatusOrderByCreatedAtDesc(filterStatus).stream()
                .map(this::mapToPendingResponse)
                .toList();
    }

    @Transactional
    public AdminAccountResponse provisionUser(UUID pendingId, ProvisionAccountRequest request, TokenPayload currentUser) {
        checkAdminAccess(currentUser);

        PendingUser pending = pendingUserRepository.findById(pendingId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hồ sơ chờ duyệt với ID: " + pendingId));

        if (!"PENDING".equalsIgnoreCase(pending.getStatus())) {
            throw new IllegalStateException("Hồ sơ này không ở trạng thái chờ duyệt (PENDING)!");
        }

        String corporateEmail = request.getCorporateEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(corporateEmail)) {
            throw new IllegalArgumentException("Email công ty " + corporateEmail + " đã tồn tại trên hệ thống!");
        }

        // 1. Tạo User chính thức
        // ponytail: sequence employee_number_seq trôi sau dữ liệu seed tay → dò tới mã trống
        // thay vì tin sequence tuyệt đối (lỗi duplicate EMP022 đã từng sập provision)
        String employeeCode = request.getEmployeeCode();
        if (employeeCode == null || employeeCode.isBlank()) {
            Long nextNumber = userRepository.getNextEmployeeNumber();
            for (int i = 0; i < 1000 && (employeeCode == null || employeeCode.isBlank()); i++) {
                String candidate = "EMP" + String.format("%03d", nextNumber + i);
                if (!userRepository.existsByEmployeeCode(candidate)) {
                    employeeCode = candidate;
                }
            }
            if (employeeCode == null || employeeCode.isBlank()) {
                throw new IllegalStateException("Không sinh được mã nhân viên mới!");
            }
        } else if (userRepository.existsByEmployeeCode(employeeCode)) {
            throw new IllegalArgumentException("Mã nhân viên " + employeeCode + " đã tồn tại trên hệ thống!");
        }

        User user = new User();
        user.setEmail(corporateEmail);
        user.setPassword(passwordEncoder.encode(request.getTemporaryPassword()));
        user.setFirstName(pending.getFirstName());
        user.setLastName(pending.getLastName());
        user.setGender(pending.getGender());
        user.setBirthDate(pending.getBirthDate());
        user.setJoinedDate(pending.getContractStartDate() != null ? pending.getContractStartDate() : LocalDate.now());
        user.setProfilePicUrl("https://ui-avatars.com/api/?name=" + pending.getFirstName() + "+" + pending.getLastName() + "&background=random");
        user.setAnnualLeaveDays(12);
        user.setUsedLeaveDays(0);
        user.setEmployeeCode(employeeCode);
        user.setActive(true);
        user.setDepartment(pending.getDepartment());
        user.setJob(pending.getJob());
        // ponytail: users.shift_id NOT NULL nhưng HR được để trống ca — mặc định ca hành chính,
        // rớt về ca đầu tiên. Không có ca nào thì báo rõ thay vì 500 constraint.
        com.minhtrung.hrm.attendance.entities.WorkShift shift = pending.getShift();
        if (shift == null) {
            java.util.List<com.minhtrung.hrm.attendance.entities.WorkShift> allShifts = workShiftRepository.findAll();
            shift = allShifts.stream()
                    .filter(s -> s.getName() != null && s.getName().toLowerCase().contains("hành chính"))
                    .findFirst()
                    .orElse(allShifts.stream().findFirst().orElse(null));
            if (shift == null) {
                throw new IllegalStateException("Chưa có ca làm việc nào trong hệ thống — hãy tạo ca trước khi cấp tài khoản!");
            }
        }
        user.setShift(shift);

        User savedUser = userRepository.save(user);

        // 2. Tạo UserProfile
        UserProfile profile = new UserProfile();
        profile.setUser(savedUser);
        profile.setPhoneNumber(pending.getPhoneNumber());
        profile.setCitizenIdNumber(pending.getCitizenId());
        profile.setPlaceOfBirth(pending.getPlaceOfBirth());
        profile.setPersonalEmail(pending.getPersonalEmail());
        userProfileRepository.save(profile);

        // 3. Tạo UserContract
        UserContract contract = new UserContract();
        contract.setUser(savedUser);
        contract.setContractType(pending.getContractType() != null ? pending.getContractType() : "Fixed-term");
        contract.setContractStartDate(pending.getContractStartDate() != null ? pending.getContractStartDate() : savedUser.getJoinedDate());
        contract.setContractEndDate(pending.getContractEndDate() != null ? pending.getContractEndDate() : savedUser.getJoinedDate().plusYears(1));
        contract.setActive(true);
        userContractRepository.save(contract);

        // 4. Tạo Salary ban đầu
        if (pending.getBaseSalary() != null) {
            Salary salary = new Salary();
            salary.setUser(savedUser);
            salary.setBaseSalary(pending.getBaseSalary().doubleValue());
            salary.setPayFrequency(PayFrequency.MONTHLY);
            salary.setWorkDays(22.0);
            salary.setStartDate(savedUser.getJoinedDate());
            salary.setActive(true);
            salaryRepository.save(salary);
        }

        // 5. Cập nhật pending_users sang APPROVED
        pending.setStatus("APPROVED");
        pendingUserRepository.save(pending);

        log.info("Admin {} đã cấp tài khoản chính thức thành công cho {} ({}) với Email: {}",
                currentUser.getUserId(), savedUser.getUserId(), savedUser.getEmail(), corporateEmail);

        return mapToAccountResponse(savedUser);
    }

    @Transactional
    public void rejectPendingUser(UUID pendingId, RejectPendingUserRequest request, TokenPayload currentUser) {
        checkAdminAccess(currentUser);

        PendingUser pending = pendingUserRepository.findById(pendingId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hồ sơ chờ duyệt với ID: " + pendingId));

        pending.setStatus("REJECTED");
        pending.setRejectionReason(request.getReason());
        pendingUserRepository.save(pending);

        log.info("Admin {} đã từ chối hồ sơ tuyển dụng {}. Lý do: {}", currentUser.getUserId(), pendingId, request.getReason());
    }

    // ─── 2. QUẢN LÝ TÀI KHOẢN & KHÓA/MỞ KHÓA ──────────────────────────

    /**
     * Danh sách tài khoản (không có lương — chỉ mã NV, tên, email, phòng ban, chức danh, trạng thái,
     * số phiên — không có lương). Người được cấp PERMISSION_GRANT cần danh sách này để chọn người
     * cấp quyền; người có ACCOUNT_LOCK cần để quản lý tài khoản. Thao tác ghi cấp lại mật khẩu
     * vẫn qua checkAdminAccess.
     */
    @Transactional(readOnly = true)
    public List<AdminAccountResponse> getAllAccounts(TokenPayload currentUser) {
        if (!canManageAccounts(currentUser) && !hasPermissionGrant(currentUser)) {
            throw new AccessDeniedException("Bạn không có quyền xem danh sách tài khoản!");
        }

        return userRepository.findAll().stream()
                .map(this::mapToAccountResponse)
                .toList();
    }

    @Transactional
    public AdminAccountResponse updateAccountStatus(UUID targetUserId, AdminUpdateStatusRequest request, TokenPayload currentUser) {
        checkAccountManagementAccess(currentUser);

        if (currentUser.getUserId().equals(targetUserId)) {
            throw new IllegalArgumentException("Không thể tự thay đổi trạng thái hoạt động của chính tài khoản mình đang đăng nhập!");
        }

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        boolean newStatus = Boolean.TRUE.equals(request.getIsActive());
        targetUser.setActive(newStatus);
        userRepository.save(targetUser);

        if (!newStatus) {
            // Cưỡng chế ngắt toàn bộ phiên đăng nhập
            List<UserSession> sessions = userSessionRepository.findByUserId(targetUserId);
            for (UserSession s : sessions) {
                s.setRevoked(true);
                userSessionRepository.save(s);
                sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
            }
            log.warn("Admin {} đã khóa tài khoản của nhân viên {} ({}). Lý do: {}",
                    currentUser.getUserId(), targetUser.getUserId(), targetUser.getEmail(), request.getReason());
        } else {
            log.info("Admin {} đã kích hoạt lại tài khoản của nhân viên {} ({})",
                    currentUser.getUserId(), targetUser.getUserId(), targetUser.getEmail());
        }

        return mapToAccountResponse(targetUser);
    }

    @Transactional
    public void resetUserPassword(UUID targetUserId, AdminResetPasswordRequest request, TokenPayload currentUser) {
        checkAdminAccess(currentUser);

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nhân viên với ID: " + targetUserId));

        targetUser.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(targetUser);

        // Sau khi reset mật khẩu, đá toàn bộ phiên cũ ra để bắt buộc đăng nhập lại
        List<UserSession> sessions = userSessionRepository.findByUserId(targetUserId);
        for (UserSession s : sessions) {
            s.setRevoked(true);
            userSessionRepository.save(s);
            sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
        }

        log.info("Admin {} đã đặt lại mật khẩu tạm thời cho nhân viên {} ({})",
                currentUser.getUserId(), targetUser.getUserId(), targetUser.getEmail());
    }

    // ─── 3. QUẢN LÝ PHIÊN & THIẾT BỊ (SESSIONS) ──────────────────────

    @Transactional(readOnly = true)
    public List<AdminSessionResponse> getAllSessions(TokenPayload currentUser, String keyword, UUID userId) {
        // Tự xem phiên của chính mình (trang /settings) — không cần quyền quản trị.
        // Ưu tiên userId == chính mình: bỏ qua keyword để không lộ phiên người khác.
        boolean isSelf = currentUser != null && userId != null && userId.equals(currentUser.getUserId());
        if (!isSelf) {
            checkAccountManagementAccess(currentUser);
        }

        List<UserSession> sessions;
        if (userId != null) {
            sessions = userSessionRepository.findByUserId(userId);
        } else {
            sessions = userSessionRepository.findAll();
        }

        List<AdminSessionResponse> result = new ArrayList<>();
        String kw = (keyword != null && !keyword.isBlank()) ? keyword.trim().toLowerCase() : null;

        for (UserSession s : sessions) {
            User u = userRepository.findById(s.getUserId()).orElse(null);
            AdminSessionResponse resp = mapToSessionResponse(s, u);

            if (kw != null) {
                String fullName = (resp.getUserFullName() != null) ? resp.getUserFullName().toLowerCase() : "";
                String email = (resp.getUserEmail() != null) ? resp.getUserEmail().toLowerCase() : "";
                String code = (resp.getEmployeeCode() != null) ? resp.getEmployeeCode().toLowerCase() : "";
                String dept = (resp.getDepartmentName() != null) ? resp.getDepartmentName().toLowerCase() : "";
                String ip = (resp.getIpAddr() != null) ? resp.getIpAddr().toLowerCase() : "";

                boolean matches = fullName.contains(kw) 
                        || email.contains(kw) 
                        || code.contains(kw) 
                        || dept.contains(kw)
                        || ip.contains(kw);

                if (!matches) {
                    continue;
                }
            }

            result.add(resp);
        }

        return result;
    }

    @Transactional
    public void revokeSession(UUID sessionId, TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác quản trị!");
        }
        UserSession session = userSessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phiên đăng nhập với ID: " + sessionId));

        // Đuổi phiên của chính mình thì không cần quyền quản trị; phiên người khác thì cần.
        if (!session.getUserId().equals(currentUser.getUserId())) {
            checkAccountManagementAccess(currentUser);
        }

        session.setRevoked(true);
        userSessionRepository.save(session);
        sessionBlacklistService.blacklistSession(sessionId, 15);

        log.info("User {} đã thu hồi phiên đăng nhập {} của user {}", currentUser.getUserId(), sessionId, session.getUserId());
    }

    @Transactional
    public void revokeAllUserSessions(UUID targetUserId, TokenPayload currentUser) {
        if (!targetUserId.equals(currentUser.getUserId())) {
            checkAccountManagementAccess(currentUser);
        }
        doRevokeAllUserSessions(targetUserId, currentUser);
    }

    /** Không check quyền — dùng nội bộ khi đổi grant cần đá phiên cũ (người gọi đã qua check riêng). */
    private void doRevokeAllUserSessions(UUID targetUserId, TokenPayload actor) {
        List<UserSession> sessions = userSessionRepository.findByUserId(targetUserId);
        for (UserSession s : sessions) {
            s.setRevoked(true);
            userSessionRepository.save(s);
            sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
        }

        log.info("Admin {} đã thu hồi toàn bộ {} phiên đăng nhập của user {}",
                actor.getUserId(), sessions.size(), targetUserId);
    }

    // ─── 4. PHÂN QUYỀN THEO NGƯỜI (GRANTS) ────────────────────────────

    @Transactional(readOnly = true)
    public List<UserPermissionResponse> getUserPermissions(UUID targetUserId, TokenPayload currentUser) {
        checkPermissionGrantAccess(currentUser);
        return permissionService.listByUserId(targetUserId).stream()
                .map(this::mapToPermissionResponse)
                .toList();
    }

    @Transactional
    public List<UserPermissionResponse> saveUserPermissions(UUID targetUserId, List<String> keys, TokenPayload currentUser) {
        checkPermissionGrantAccess(currentUser);
        if (currentUser.getUserId() != null && currentUser.getUserId().equals(targetUserId)) {
            throw new IllegalArgumentException("Không thể tự cấp / tự gỡ quyền cho chính mình! Nhờ SysAdmin hoặc người được ủy quyền khác thực hiện.");
        }
        List<PermissionGrant> saved = permissionService.replaceGrants(targetUserId, keys, currentUser.getUserId());
        // ponytail: hiệu lực ngay — đá văng sessions để JWT mới nhét grants mới
        doRevokeAllUserSessions(targetUserId, currentUser);
        String granterName = (currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUserId().toString());
        return saved.stream()
                .map(g -> UserPermissionResponse.builder()
                        .key(g.getPermission().name())
                        .label(g.getPermission().getLabel())
                        .grantedBy(g.getGrantedBy())
                        .grantedByName(granterName)
                        .grantedAt(g.getGrantedAt())
                        .build())
                .toList();
    }

    private UserPermissionResponse mapToPermissionResponse(PermissionGrant g) {
        String granterName = userRepository.findById(g.getGrantedBy())
                .map(u -> ((u.getFirstName() != null ? u.getFirstName() : "") + " " + (u.getLastName() != null ? u.getLastName() : "")).trim())
                .orElse(g.getGrantedBy().toString());
        return UserPermissionResponse.builder()
                .key(g.getPermission().name())
                .label(g.getPermission().getLabel())
                .grantedBy(g.getGrantedBy())
                .grantedByName(granterName)
                .grantedAt(g.getGrantedAt())
                .build();
    }

    // ─── HELPER MAPPERS ──────────────────────────────────────────────

    private PendingUserResponse mapToPendingResponse(PendingUser p) {
        String createdByName = null;
        if (p.getCreatedBy() != null) {
            createdByName = (p.getCreatedBy().getFirstName() + " " + p.getCreatedBy().getLastName()).trim();
        }

        return PendingUserResponse.builder()
                .pendingId(p.getPendingId())
                .firstName(p.getFirstName())
                .lastName(p.getLastName())
                .fullName((p.getFirstName() + " " + p.getLastName()).trim())
                .gender(p.getGender())
                .birthDate(p.getBirthDate())
                .personalEmail(p.getPersonalEmail())
                .phoneNumber(p.getPhoneNumber())
                .citizenId(p.getCitizenId())
                .placeOfBirth(p.getPlaceOfBirth())
                .departmentId(p.getDepartment() != null ? p.getDepartment().getDepartmentId() : null)
                .departmentName(p.getDepartment() != null ? p.getDepartment().getName() : null)
                .jobId(p.getJob() != null ? p.getJob().getJobId() : null)
                .jobTitle(p.getJob() != null ? p.getJob().getTitle() : null)
                .shiftId(p.getShift() != null ? p.getShift().getShiftId() : null)
                .shiftName(p.getShift() != null ? p.getShift().getName() : null)
                .baseSalary(p.getBaseSalary())
                .contractType(p.getContractType())
                .contractStartDate(p.getContractStartDate())
                .contractEndDate(p.getContractEndDate())
                .status(p.getStatus())
                .rejectionReason(p.getRejectionReason())
                .createdByName(createdByName)
                .createdAt(p.getCreatedAt())
                .build();
    }

    private AdminAccountResponse mapToAccountResponse(User u) {
        int activeSessions = (int) userSessionRepository.findByUserId(u.getUserId()).stream()
                .filter(s -> !s.isRevoked())
                .count();

        return AdminAccountResponse.builder()
                .userId(u.getUserId())
                .employeeCode(u.getEmployeeCode())
                .fullName((u.getFirstName() + " " + u.getLastName()).trim())
                .email(u.getEmail())
                .departmentName(u.getDepartment() != null ? u.getDepartment().getName() : null)
                .jobTitle(u.getJob() != null ? u.getJob().getTitle() : null)
                .isActive(u.isActive())
                .joinedDate(u.getJoinedDate())
                .activeSessionCount(activeSessions)
                .build();
    }

    private AdminSessionResponse mapToSessionResponse(UserSession s, User u) {
        ClientMetaData meta = s.getMetaData();
        return AdminSessionResponse.builder()
                .sessionId(s.getSessionId())
                .userId(s.getUserId())
                .employeeCode(u != null ? u.getEmployeeCode() : null)
                .userFullName(u != null ? (u.getFirstName() + " " + u.getLastName()).trim() : "Unknown")
                .userEmail(u != null ? u.getEmail() : "Unknown")
                .departmentName(u != null && u.getDepartment() != null ? u.getDepartment().getName() : null)
                .deviceType(meta != null ? meta.getDeviceType() : null)
                .deviceOS(meta != null ? meta.getDeviceOS() : null)
                .browser(meta != null ? meta.getBrowser() : null)
                .ipAddr(meta != null ? meta.getIpAddr() : null)
                .city(meta != null ? meta.getCity() : null)
                .country(meta != null ? meta.getCountry() : null)
                .isp(meta != null ? meta.getIsp() : null)
                .createdAt(s.getCreatedAt())
                .lastActiveAt(s.getLastActiveAt())
                .revoked(s.isRevoked())
                .build();
    }
}
