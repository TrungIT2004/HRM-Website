package com.minhtrung.hrm.auth.services;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import java.util.Base64;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.auth.dtos.internals.UserAuthInfo;
import com.minhtrung.hrm.auth.dtos.requests.ChangePasswordRequest;
import com.minhtrung.hrm.auth.dtos.requests.SignInRequest;
import com.minhtrung.hrm.auth.dtos.requests.SignUpRequest;
import com.minhtrung.hrm.auth.dtos.response.SignInResponse;
import com.minhtrung.hrm.auth.entities.UserSession;
import com.minhtrung.hrm.auth.enums.AuthErrorCode;
import com.minhtrung.hrm.auth.exceptions.AuthenticationException;
import com.minhtrung.hrm.auth.repositories.UserSessionRepository;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.JobRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class AuthService {
    private final EmailService emailService;
    private final JwtService jwtService;    
    private final UserRepository userRepository;
    private final UserSessionRepository userSessionRepository;
    private final PasswordEncoder passwordEncoder;
    private final DepartmentRepository departmentRepository;
    private final JobRepository jobRepository;
    private final SessionBlacklistService sessionBlacklistService;

    @Value("${jwt.secret.access}")
    private String accessSecret;

    @Value("${jwt.secret.refresh}")
    private String refreshSecret;

    AuthService(EmailService emailService, JwtService jwtService, UserRepository userRepository,
            UserSessionRepository userSessionRepository, PasswordEncoder passwordEncoder,
            DepartmentRepository departmentRepository, JobRepository jobRepository,
            SessionBlacklistService sessionBlacklistService) {
        this.emailService = emailService;
        this.jwtService = jwtService;
        this.userRepository = userRepository;
        this.userSessionRepository = userSessionRepository;
        this.passwordEncoder = passwordEncoder;
        this.departmentRepository = departmentRepository;
        this.jobRepository = jobRepository;
        this.sessionBlacklistService = sessionBlacklistService;
    }
    
    public User register(SignUpRequest request) {
        try {
            Department department = departmentRepository.getReferenceById(request.getDepartmentId());
            Job job = jobRepository.getReferenceById(request.getJobId());

            User user = new User();
            user.setEmail(request.getEmail());
            user.setFirstName(request.getFirstName());
            user.setLastName(request.getLastName());
            user.setGender(request.getGender());
            user.setProfilePicUrl(request.getProfilePicUrl());
            user.setAnnualLeaveDays(12);
            user.setUsedLeaveDays(0);
            user.setBirthDate(request.getBirthDate());
            user.setJoinedDate(request.getJoinedDate());
            user.setDepartment(department);
            user.setJob(job);

            String password = request.getPassword();
            String hashedPassword = passwordEncoder.encode(password);
            user.setPassword(hashedPassword);

            String employeeCode = request.getEmployeeCode();

            if (employeeCode == null) {
                Long nextNumber = userRepository.getNextEmployeeNumber();
                employeeCode = "EMP" + String.format("%03d", nextNumber);
            }

            user.setEmployeeCode(employeeCode);              

            User saved = userRepository.save(user);
            log.info("Đăng ký tài khoản thành công. Email: {}, Mã NV: {}, Phòng ban: {}",
                    request.getEmail(), saved.getEmployeeCode(),
                    saved.getDepartment() != null ? saved.getDepartment().getName() : "N/A");
            return saved;
        } catch (Exception ex) {
            throw new RuntimeException(ex.getMessage());

        }
    }

    public String hash(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hashBytes);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 not supported", e);
        }
    }
    
    public SignInResponse generateToken(UUID deviceId, ClientMetaData clientMetaData, UserAuthInfo user) {
        UUID userId = user.getUserId();
        String email = user.getEmail();
        String fullName = user.getFullName();
        String profilePicUrl = user.getProfilePicUrl();
        String department = user.getDepartment();
        String job = user.getJob();
    

        UserSession session = new UserSession();
        UUID sessionId = UUID.randomUUID();
        session.setSessionId(sessionId);
        session.setUserId(userId);
        session.setDeviceId(deviceId);
        session.setMetaData(clientMetaData);

        TokenPayload tokenPayload = new TokenPayload();
        tokenPayload.setUserId(userId);
        tokenPayload.setSessionId(sessionId);
        tokenPayload.setDeviceId(deviceId);
        tokenPayload.setEmail(user.getEmail());
        tokenPayload.setFullName(fullName);
        tokenPayload.setDepartment(department);
        tokenPayload.setJob(job);

        String accessToken = jwtService.generateAccessToken(tokenPayload);
        String refreshToken = jwtService.generateRefreshToken(tokenPayload);

        session.setToken(hash(refreshToken));
        userSessionRepository.save(session);

        SignInResponse signInResponse = new SignInResponse();
        signInResponse.setUserId(userId);
        signInResponse.setAccessToken(accessToken);
        signInResponse.setRefreshToken(refreshToken);
        signInResponse.setFullName(fullName);
        signInResponse.setEmail(email);
        signInResponse.setProfilePicUrl(profilePicUrl);
        signInResponse.setDepartment(department);
        signInResponse.setJob(job);

        return signInResponse;
    }
    
    public SignInResponse updateToken(ClientMetaData clientMetaData, TokenPayload tokenPayload, UserSession session) {
        String fullName = tokenPayload.getFullName();
        String email = tokenPayload.getEmail();
        String profilePicUrl = tokenPayload.getProfilePicUrl();
        String department = tokenPayload.getDepartment();
        String job = tokenPayload.getJob();

        String accessToken = jwtService.generateAccessToken(tokenPayload);
        String refreshToken = jwtService.generateRefreshToken(tokenPayload);

        session.setToken(hash(refreshToken));
        session.setMetaData(clientMetaData);
        userSessionRepository.save(session);

        SignInResponse signInResponse = new SignInResponse();
        signInResponse.setAccessToken(accessToken);
        signInResponse.setRefreshToken(refreshToken);
        signInResponse.setFullName(fullName);
        signInResponse.setEmail(email);
        signInResponse.setProfilePicUrl(profilePicUrl);
        signInResponse.setDepartment(department);
        signInResponse.setJob(job);

        return signInResponse;
    }
    
    public SignInResponse signIn(SignInRequest signInRequest, UUID deviceId, ClientMetaData clientMetaData) {
        UserAuthInfo user = userRepository.getUserInfo(signInRequest.getEmail());

        if (user == null || user.getUserId() == null) {
            throw new AuthenticationException(AuthErrorCode.USER_NOT_FOUND,
                    "User doesn't exists");
        }

        if (!user.isActive()) {
            throw new AuthenticationException(AuthErrorCode.ACCOUNT_DISABLED,
                    "Tài khoản của bạn đã bị vô hiệu hóa hoặc đã thôi việc. Vui lòng liên hệ phòng Nhân sự!");
        }

        if (passwordEncoder.matches(signInRequest.getPassword(), user.getPassword())) {
            List<UserSession> sessionList = userSessionRepository.findByUserId(user.getUserId());

            if (sessionList.isEmpty()) {
                System.out.println("First Login");
                return generateToken(deviceId, clientMetaData, user);
            }

            UserSession session = sessionList.stream()
                    .filter(s -> s.getDeviceId().equals(deviceId))
                    .findFirst()
                    .orElse(null);

            if (session == null || deviceId.equals("")) {
                log.warn("Đăng nhập từ thiết bị chưa từng đăng nhập. Email: {}, DeviceId: {}",
                        signInRequest.getEmail(), deviceId);
                emailService.sendUntrustedDeviceWarning(user.getEmail());
                return generateToken(deviceId, clientMetaData, user);
            } else if (session != null && session.getDeviceId().equals(deviceId)) {
                // 1. Xóa session cũ (để sessionId cũ tiếp tục bị giam trong Redis)
                userSessionRepository.delete(session);

                log.info("Đăng nhập thành công (thiết bị tin cậy). Email: {}, DeviceId: {}", user.getEmail(),
                        deviceId);

                // 2. Gọi generateToken là xong toàn bộ (tự tạo session mới, tự sinh token mới, tự return)
                return generateToken(deviceId, clientMetaData, user);
            }
        } else {
            log.warn("Đăng nhập thất bại. Sai mật khẩu cho email: {}", signInRequest.getEmail());
            throw new AuthenticationException(AuthErrorCode.USER_CREDENTIALS_INVALID, "Wrong credentials");
        }
        
        return null;
    }
    
    
    public SignInResponse autoSignIn(String token, UUID deviceId, ClientMetaData clientMetaData) {
        if (jwtService.isTokenValid(token, refreshSecret)) {
            TokenPayload payload = jwtService.extractAll(token, refreshSecret);

            UUID sessionId = payload.getSessionId();
            UUID userId = payload.getUserId();
            UUID deviceIdFromToken = payload.getDeviceId();

            UserSession session = userSessionRepository
                    .findById(sessionId)
                    .orElseThrow(() -> new AuthenticationException(AuthErrorCode.SESSION_NOT_FOUND,
                            "User's session not found"));

            if (!session.getUserId().equals(userId)) {
                log.warn("Cảnh báo bảo mật: UserId trong Session không khớp với Token. SessionId: {}, UserId: {}", sessionId, userId);
                throw new AuthenticationException(AuthErrorCode.USER_MISMATCH, "User mismatch");
            }

            if (!session.getDeviceId().equals(deviceIdFromToken)) {
                log.warn("Cảnh báo bảo mật: DeviceId không khớp giữa Session và Token. SessionId: {}, DeviceId: {}", sessionId, deviceIdFromToken);
                throw new AuthenticationException(AuthErrorCode.DEVICE_MISMATCH, "Device mismatch");
            }

            if (!deviceId.equals(deviceIdFromToken)) {
                log.warn("Cảnh báo bảo mật: DeviceId trong Cookie không khớp Token. DeviceId (Cookie): {}, DeviceId (Token): {}", deviceId, deviceIdFromToken);
                throw new AuthenticationException(AuthErrorCode.DEVICE_COOKIE_MISMATCH, "DeviceID(Cookie) mismatch");
            }

            if (session.isRevoked()) {
                log.warn("Cảnh báo bảo mật: Phiên đăng nhập đã bị thu hồi. SessionId: {}, UserId: {}", sessionId, userId);
                throw new AuthenticationException(AuthErrorCode.SESSION_REVOKED, "Session revoked");
            }

            // Kiểm tra tài khoản người dùng có đang hoạt động hay đã bị khóa / thôi việc
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new AuthenticationException(AuthErrorCode.USER_NOT_FOUND, "User not found"));

            if (!user.isActive()) {
                log.warn("Cảnh báo bảo mật: Tài khoản đã bị vô hiệu hóa hoặc thôi việc nhưng cố gắng auto-login. UserId: {}, Email: {}, SessionId: {}",
                        userId, user.getEmail(), sessionId);
                session.setRevoked(true);
                userSessionRepository.save(session);
                sessionBlacklistService.blacklistSession(sessionId, 15);
                throw new AuthenticationException(AuthErrorCode.ACCOUNT_DISABLED,
                        "Tài khoản của bạn đã bị vô hiệu hóa hoặc đã thôi việc. Vui lòng liên hệ phòng Nhân sự!");
            }

            if (!hash(token).equals(session.getToken())) {
                log.error("CẢNH BÁO NGHIÊM TRỌNG: Phát hiện Token bị làm giả / Session bị tấn công! SessionId: {}, UserId: {}. Đang thu hồi phiên.", sessionId, userId);
                session.setRevoked(true);
                userSessionRepository.save(session);
                sessionBlacklistService.blacklistSession(sessionId, 15);
                throw new AuthenticationException(AuthErrorCode.SESSION_COMPROMISED, "Session compromised");
            }     

            System.out.println("Redirect to home page");
            log.info("Auto-login thành công. UserId: {}, SessionId: {}, DeviceId: {}", userId, sessionId, deviceIdFromToken);
            return updateToken(clientMetaData, payload, session);
        }
        
        throw new AuthenticationException(AuthErrorCode.SESSION_MISMATCH, "User's session not match");
    }
    
    public void signOut(String token) {
        if (jwtService.isTokenValid(token, refreshSecret)) {
            TokenPayload payload = jwtService.extractAll(token, refreshSecret);

            UUID sessionId = payload.getSessionId();

            UserSession session = userSessionRepository
                    .findById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Session not found"));
            
            session.setRevoked(true);
            userSessionRepository.save(session);
            sessionBlacklistService.blacklistSession(sessionId, 15);
            log.info("Đăng xuất thành công. SessionId: {}, UserId: {}", sessionId, session.getUserId());
        } else {
            return;
        }
    }

    public void changePassword(UUID userId, ChangePasswordRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException(AuthErrorCode.USER_NOT_FOUND, "Không tìm thấy người dùng"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new AuthenticationException(AuthErrorCode.USER_CREDENTIALS_INVALID, "Mật khẩu cũ không chính xác");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("Mật khẩu mới và xác nhận mật khẩu không khớp");
        }

        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Mật khẩu mới không được trùng với mật khẩu hiện tại");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Thu hồi toàn bộ các phiên đăng nhập cũ trong Redis để bảo mật
        List<UserSession> activeSessions = userSessionRepository.findByUserId(userId);
        for (UserSession s : activeSessions) {
            s.setRevoked(true);
            userSessionRepository.save(s);
            sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
        }

        log.info("Người dùng {} đã đổi mật khẩu thành công và các phiên cũ đã được thu hồi.", userId);
    }
}
