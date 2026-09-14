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
import com.minhtrung.hrm.admin.dtos.requests.ProvisionAccountRequest;
import com.minhtrung.hrm.admin.dtos.requests.RejectPendingUserRequest;
import com.minhtrung.hrm.admin.dtos.responses.AdminAccountResponse;
import com.minhtrung.hrm.admin.dtos.responses.AdminSessionResponse;
import com.minhtrung.hrm.admin.dtos.responses.PendingUserResponse;
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
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.JobRepository;
import com.minhtrung.hrm.employees.repositories.SalaryRepository;
import com.minhtrung.hrm.employees.repositories.UserContractRepository;
import com.minhtrung.hrm.employees.repositories.UserProfileRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;

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
    private final DepartmentRepository departmentRepository;
    private final JobRepository jobRepository;
    private final WorkShiftRepository workShiftRepository;
    private final SessionBlacklistService sessionBlacklistService;
    private final PasswordEncoder passwordEncoder;

    /**
     * Kiểm tra quyền System Admin (theo Hướng B: IT + System Administrator)
     */
    public void checkAdminAccess(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác quản trị!");
        }

        boolean isIT = "Information Technology".equalsIgnoreCase(currentUser.getDepartment());
        boolean isSysAdmin = isIT && currentUser.getJob() != null && (currentUser.getJob().contains("System Administrator") || currentUser.getJob().contains("Admin"));
        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());

        if (!isSysAdmin && !isExecutive) {
            throw new AccessDeniedException("Chỉ Quản trị viên Hệ thống (System Administrator) hoặc Ban Giám Đốc mới có quyền truy cập khu vực này!");
        }
    }

    // ─── 1. ONBOARDING & CẤP TÀI KHOẢN (PROVISIONING) ────────────────

    @Transactional(readOnly = true)
    public List<PendingUserResponse> getPendingUsers(TokenPayload currentUser, String status) {
        checkAdminAccess(currentUser);
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
        String employeeCode = request.getEmployeeCode();
        if (employeeCode == null || employeeCode.isBlank()) {
            Long nextNumber = userRepository.getNextEmployeeNumber();
            employeeCode = "EMP" + String.format("%03d", nextNumber);
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
        user.setShift(pending.getShift());

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

    @Transactional(readOnly = true)
    public List<AdminAccountResponse> getAllAccounts(TokenPayload currentUser) {
        checkAdminAccess(currentUser);

        return userRepository.findAll().stream()
                .map(this::mapToAccountResponse)
                .toList();
    }

    @Transactional
    public AdminAccountResponse updateAccountStatus(UUID targetUserId, AdminUpdateStatusRequest request, TokenPayload currentUser) {
        checkAdminAccess(currentUser);

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
        checkAdminAccess(currentUser);

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
        checkAdminAccess(currentUser);

        UserSession session = userSessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phiên đăng nhập với ID: " + sessionId));

        session.setRevoked(true);
        userSessionRepository.save(session);
        sessionBlacklistService.blacklistSession(sessionId, 15);

        log.info("Admin {} đã thu hồi phiên đăng nhập {} của user {}", currentUser.getUserId(), sessionId, session.getUserId());
    }

    @Transactional
    public void revokeAllUserSessions(UUID targetUserId, TokenPayload currentUser) {
        checkAdminAccess(currentUser);

        List<UserSession> sessions = userSessionRepository.findByUserId(targetUserId);
        for (UserSession s : sessions) {
            s.setRevoked(true);
            userSessionRepository.save(s);
            sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
        }

        log.info("Admin {} đã thu hồi toàn bộ {} phiên đăng nhập của user {}",
                currentUser.getUserId(), sessions.size(), targetUserId);
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
