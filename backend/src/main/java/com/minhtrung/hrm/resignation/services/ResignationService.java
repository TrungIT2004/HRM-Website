package com.minhtrung.hrm.resignation.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.entities.UserContract;
import com.minhtrung.hrm.employees.repositories.UserContractRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.resignation.dtos.requests.ApproveResignationRequest;
import com.minhtrung.hrm.resignation.dtos.requests.CreateResignationRequest;
import com.minhtrung.hrm.resignation.dtos.requests.TransferRequest;
import com.minhtrung.hrm.resignation.dtos.responses.ResignationResponse;
import com.minhtrung.hrm.resignation.entities.ResignationRequest;
import com.minhtrung.hrm.resignation.enums.ResignationErrorCode;
import com.minhtrung.hrm.resignation.enums.ResignationStatus;
import com.minhtrung.hrm.resignation.exceptions.ResignationException;
import com.minhtrung.hrm.resignation.repositories.ResignationRequestRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class ResignationService {

    private final ResignationRequestRepository resignationRequestRepository;
    private final UserContractRepository userContractRepository;
    private final UserRepository userRepository;

    /**
     * 1. Nhân viên tạo đơn xin thôi việc
     */
    @Transactional
    public ResignationResponse createResignationRequest(UserRole userRole, CreateResignationRequest request) {
        UUID userId = userRole.getUserId();

        // 1. Chặn nộp trùng lặp nếu đang có đơn chưa hoàn tất
        boolean hasActiveRequest = resignationRequestRepository.existsByUser_UserIdAndStatusIn(
                userId, List.of(ResignationStatus.PENDING, ResignationStatus.MANAGER_APPROVED, ResignationStatus.APPROVED));
        if (hasActiveRequest) {
            throw new ResignationException(ResignationErrorCode.ACTIVE_REQUEST_EXISTS,
                    "Bạn đang có một đơn thôi việc đang được xử lý, không thể nộp thêm đơn mới.");
        }

        // 2. Lấy thông tin hợp đồng hiện tại
        UserContract userContract = userContractRepository.findByUser_UserId(userId)
                .orElseThrow(() -> new ResignationException(ResignationErrorCode.CONTRACT_NOT_FOUND,
                        "Không tìm thấy thông tin hợp đồng của nhân viên"));

        String contractType = userContract.getContractType() != null ? userContract.getContractType().trim() : "";
        LocalDate lastWorkingDate = request.getLastWorkingDate();

        // 3. Đo thời gian báo trước từ hôm nay đến ngày làm việc cuối cùng
        long duration = ChronoUnit.DAYS.between(LocalDate.now(), lastWorkingDate);

        // 3 loại chuẩn: Indefinite (>= 45 ngày), Probation (>= 3 ngày), Fixed-term (>= 30 ngày)
        boolean isIndefinite = "Indefinite".equalsIgnoreCase(contractType) || contractType.contains("Không xác định thời hạn");
        boolean isProbation = "Probation".equalsIgnoreCase(contractType) || contractType.contains("Thử việc");

        int requiredNoticeDays = isIndefinite ? 45 : (isProbation ? 3 : 30);

        if (duration < requiredNoticeDays) {
            throw new ResignationException(ResignationErrorCode.INVALID_NOTICE_PERIOD,
                    "Theo loại hợp đồng (" + (contractType.isEmpty() ? "Mặc định" : contractType) 
                    + "), bạn phải thông báo nghỉ việc trước ít nhất " + requiredNoticeDays + " ngày.");
        }

        // 4. Lấy đầy đủ thông tin nhân viên
        User user = userRepository.findById(userId).orElseThrow(() ->
                new ResignationException(ResignationErrorCode.CONTRACT_NOT_FOUND, "Không tìm thấy thông tin nhân viên"));

        ResignationRequest resignationRequest = ResignationRequest.builder()
                .user(user)
                .submittedTime(LocalDateTime.now())
                .lastWorkingDate(lastWorkingDate)
                .reason(request.getReason())
                .status(ResignationStatus.PENDING)
                .build();

        ResignationRequest saved = resignationRequestRepository.save(resignationRequest);
        log.info("Nhân viên {} đã nộp đơn xin thôi việc. Ngày làm việc cuối: {}", userId, lastWorkingDate);

        return mapToResponse(saved);
    }

    /**
     * 2. Cấp 1: Trưởng phòng ban duyệt kế hoạch bàn giao (hoặc Từ chối)
     */
    @Transactional
    public void transferResignationRequest(UserRole userRole, TransferRequest request) {
        ResignationRequest resignationRequest = resignationRequestRepository.findById(request.getResignationId())
                .orElseThrow(() -> new ResignationException(ResignationErrorCode.RESIGNATION_NOT_FOUND,
                        "Không tìm thấy đơn xin thôi việc"));

        // Phải ở trạng thái PENDING mới được duyệt Cấp 1
        if (resignationRequest.getStatus() != ResignationStatus.PENDING) {
            throw new ResignationException(ResignationErrorCode.INVALID_STATUS_TRANSITION,
                    "Đơn thôi việc không ở trạng thái chờ duyệt bàn giao (PENDING)");
        }

        UUID approverId = userRole.getUserId();
        UUID requestorId = resignationRequest.getUserId();

        if (approverId.equals(requestorId)) {
            throw new ResignationException(ResignationErrorCode.SELF_APPROVAL_NOT_ALLOWED,
                    "Bạn không thể tự phê duyệt đơn xin thôi việc của chính mình");
        }

        String requestorDept = resignationRequest.getUser() != null && resignationRequest.getUser().getDepartment() != null
                ? resignationRequest.getUser().getDepartment().getName() : "";
        String approverDept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        String approverJob = userRole.getJob() != null ? userRole.getJob() : "";

        boolean isDepartmentHead = approverDept.equals(requestorDept) && approverJob.startsWith("Department Head");
        boolean isExecutive = "Executive Leadership".equals(approverDept);

        if (!isDepartmentHead && !isExecutive) {
            throw new ResignationException(ResignationErrorCode.UNAUTHORIZED_ACTION,
                    "Chỉ Trưởng phòng ban trực tiếp hoặc Ban Giám Đốc mới có quyền duyệt bàn giao đơn này");
        }

        // Validate trạng thái duyệt Cấp 1
        ResignationStatus newStatus = request.getStatus();
        if (newStatus != ResignationStatus.MANAGER_APPROVED && newStatus != ResignationStatus.MANAGER_REJECTED) {
            throw new ResignationException(ResignationErrorCode.INVALID_STATUS_TRANSITION,
                    "Trưởng phòng chỉ có thể chọn Duyệt bàn giao (MANAGER_APPROVED) hoặc Từ chối (MANAGER_REJECTED)");
        }

        User approverProxy = userRepository.getReferenceById(approverId);
        resignationRequest.setManager(approverProxy);
        resignationRequest.setStatus(newStatus);
        resignationRequest.setManagerComment(request.getManagerComment());
        resignationRequest.setManagerApprovedAt(LocalDateTime.now());

        resignationRequestRepository.save(resignationRequest);
        log.info("Trưởng phòng {} đã duyệt đơn thôi việc {} sang trạng thái {}", approverId, request.getResignationId(), newStatus);
    }

    /**
     * 3. Cấp 2: Ban Giám Đốc hoặc Phòng Nhân sự (HR) phê duyệt chính thức
     */
    @Transactional
    public void finalizedResignationRequest(UserRole userRole, ApproveResignationRequest request) {
        ResignationRequest resignationRequest = resignationRequestRepository.findById(request.getResignationId())
                .orElseThrow(() -> new ResignationException(ResignationErrorCode.RESIGNATION_NOT_FOUND,
                        "Không tìm thấy đơn xin thôi việc"));

        // Đơn phải ở trạng thái MANAGER_APPROVED (hoặc PENDING nếu người nộp chính là Trưởng phòng)
        boolean isRequestorDeptHead = resignationRequest.getUser() != null 
                && resignationRequest.getUser().getJob() != null 
                && resignationRequest.getUser().getJob().getTitle() != null
                && resignationRequest.getUser().getJob().getTitle().startsWith("Department Head");

        boolean canApproveStatus = resignationRequest.getStatus() == ResignationStatus.MANAGER_APPROVED
                || (isRequestorDeptHead && resignationRequest.getStatus() == ResignationStatus.PENDING);

        if (!canApproveStatus) {
            throw new ResignationException(ResignationErrorCode.INVALID_STATUS_TRANSITION,
                    "Đơn thôi việc chưa được duyệt bàn giao bởi Trưởng phòng");
        }

        UUID approverId = userRole.getUserId();
        UUID requestorId = resignationRequest.getUserId();

        if (approverId.equals(requestorId)) {
            throw new ResignationException(ResignationErrorCode.SELF_APPROVAL_NOT_ALLOWED,
                    "Bạn không thể tự phê duyệt đơn xin thôi việc của chính mình");
        }

        String approverDept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        boolean isExecutive = "Executive Leadership".equals(approverDept);
        boolean isHR = "Human Resources".equals(approverDept);

        if (!isExecutive && !isHR) {
            throw new ResignationException(ResignationErrorCode.UNAUTHORIZED_ACTION,
                    "Chỉ Ban Giám Đốc hoặc Phòng Nhân sự (HR) mới có quyền phê duyệt chính thức đơn thôi việc");
        }

        ResignationStatus newStatus = request.getStatus();
        if (newStatus != ResignationStatus.APPROVED && newStatus != ResignationStatus.REJECTED) {
            throw new ResignationException(ResignationErrorCode.INVALID_STATUS_TRANSITION,
                    "Trạng thái phê duyệt cấp cao chỉ có thể là Duyệt (APPROVED) hoặc Từ chối (REJECTED)");
        }

        User executiveProxy = userRepository.getReferenceById(approverId);
        resignationRequest.setExecutive(executiveProxy);
        resignationRequest.setStatus(newStatus);
        resignationRequest.setExecutiveComment(request.getExecutiveComment());
        resignationRequest.setExecutiveApprovedAt(LocalDateTime.now());                

        // Trường hợp đặc biệt: Nếu ngày làm việc cuối đã qua (phê duyệt trễ) -> Hoàn tất ngay và khóa tài khoản
        if (newStatus == ResignationStatus.APPROVED && resignationRequest.getLastWorkingDate().isBefore(LocalDate.now())) {
            User requestor = resignationRequest.getUser();
            if (requestor != null) {
                requestor.setActive(false);
                userRepository.save(requestor);
            }
            resignationRequest.setStatus(ResignationStatus.COMPLETED);
            log.info("Đã khóa tài khoản nhân viên {} ngay sau khi duyệt do ngày làm việc cuối đã qua", requestorId);
        }

        resignationRequestRepository.save(resignationRequest);
        log.info("Cấp cao {} đã phê duyệt đơn thôi việc {} sang trạng thái {}", approverId, request.getResignationId(), resignationRequest.getStatus());
    }

    /**
     * 4. Hủy đơn xin thôi việc (Nhân viên chỉ có thể hủy đơn PENDING của chính mình)
     */
    @Transactional
    public void cancelResignationRequest(UserRole userRole, UUID resignationId) {
        ResignationRequest resignationRequest = resignationRequestRepository.findById(resignationId)
                .orElseThrow(() -> new ResignationException(ResignationErrorCode.RESIGNATION_NOT_FOUND,
                        "Không tìm thấy đơn xin thôi việc"));

        if (!resignationRequest.getUserId().equals(userRole.getUserId())) {
            throw new ResignationException(ResignationErrorCode.UNAUTHORIZED_ACTION,
                    "Bạn chỉ có quyền hủy đơn thôi việc của chính mình");
        }

        if (resignationRequest.getStatus() != ResignationStatus.PENDING) {
            throw new ResignationException(ResignationErrorCode.INVALID_STATUS_TRANSITION,
                    "Chỉ có thể hủy đơn thôi việc khi đang ở trạng thái chờ duyệt bàn giao (PENDING)");
        }

        resignationRequest.setStatus(ResignationStatus.CANCELLED);
        resignationRequestRepository.save(resignationRequest);
        log.info("Nhân viên {} đã hủy đơn xin thôi việc {}", userRole.getUserId(), resignationId);
    }

    /**
     * 5. Lấy danh sách đơn cá nhân của nhân viên đang đăng nhập
     */
    @Transactional(readOnly = true)
    public Page<ResignationResponse> getMyResignations(UserRole userRole, Pageable pageable) {
        return resignationRequestRepository.findByUserIdWithDetails(userRole.getUserId(), pageable)
                .map(this::mapToResponse);
    }

    /**
     * 6. Lấy danh sách đơn cần phê duyệt
     * - Trưởng phòng: Xem các đơn PENDING của nhân viên trong phòng ban
     * - Ban Giám Đốc / HR: Xem các đơn MANAGER_APPROVED (hoặc PENDING của chính các Trưởng phòng)
     */
    @Transactional(readOnly = true)
    public Page<ResignationResponse> getPendingApprovals(UserRole userRole, Pageable pageable) {
        String dept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        String job = userRole.getJob() != null ? userRole.getJob() : "";

        boolean isExecutive = "Executive Leadership".equals(dept);
        boolean isHR = "Human Resources".equals(dept);
        boolean isDeptHead = job.startsWith("Department Head");

        if (isExecutive || isHR) {
            return resignationRequestRepository.findExecutiveApprovals(userRole.getUserId(), pageable)
                    .map(this::mapToResponse);
        } else if (isDeptHead) {
            return resignationRequestRepository.findDepartmentApprovals(
                    ResignationStatus.PENDING, dept, userRole.getUserId(), pageable)
                    .map(this::mapToResponse);
        }

        return Page.empty(pageable);
    }

    /**
     * 7. Lấy toàn bộ đơn công ty (Dành cho HR / Ban Giám Đốc)
     */
    @Transactional(readOnly = true)
    public Page<ResignationResponse> getAllCompanyResignations(UserRole userRole, ResignationStatus status, Pageable pageable) {
        String dept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        boolean isExecutive = "Executive Leadership".equals(dept);
        boolean isHR = "Human Resources".equals(dept);

        if (!isExecutive && !isHR) {
            throw new ResignationException(ResignationErrorCode.UNAUTHORIZED_ACTION,
                    "Chỉ Ban Giám Đốc hoặc Phòng Nhân sự mới có quyền xem toàn bộ đơn thôi việc của công ty");
        }

        return resignationRequestRepository.findAllCompanyRequests(status, pageable)
                .map(this::mapToResponse);
    }

    /**
     * Chuyển đổi Entity sang ResignationResponse DTO
     */
    public ResignationResponse mapToResponse(ResignationRequest entity) {
        User u = entity.getUser();
        User m = entity.getManager();
        User e = entity.getExecutive();

        String employeeName = u != null 
                ? ((u.getFirstName() != null ? u.getFirstName() : "") + " " + (u.getLastName() != null ? u.getLastName() : "")).trim() 
                : null;
        String managerName = m != null 
                ? ((m.getFirstName() != null ? m.getFirstName() : "") + " " + (m.getLastName() != null ? m.getLastName() : "")).trim() 
                : null;
        String executiveName = e != null 
                ? ((e.getFirstName() != null ? e.getFirstName() : "") + " " + (e.getLastName() != null ? e.getLastName() : "")).trim() 
                : null;

        String contractType = (u != null && u.getContract() != null) ? u.getContract().getContractType() : null;
        LocalDate joinedDate = u != null ? u.getJoinedDate() : null;

        return ResignationResponse.builder()
                .resignationId(entity.getResignationId())
                .userId(u != null ? u.getUserId() : null)
                .employeeCode(u != null ? u.getEmployeeCode() : null)
                .employeeName(employeeName)
                .departmentName(u != null && u.getDepartment() != null ? u.getDepartment().getName() : null)
                .jobTitle(u != null && u.getJob() != null ? u.getJob().getTitle() : null)
                .profilePicUrl(u != null ? u.getProfilePicUrl() : null)
                .joinedDate(joinedDate)
                .contractType(contractType)
                .submittedTime(entity.getSubmittedTime())
                .lastWorkingDate(entity.getLastWorkingDate())
                .reason(entity.getReason())
                .status(entity.getStatus())
                .managerId(m != null ? m.getUserId() : null)
                .managerName(managerName)
                .managerComment(entity.getManagerComment())
                .managerApprovedAt(entity.getManagerApprovedAt())
                .executiveId(e != null ? e.getUserId() : null)
                .executiveName(executiveName)
                .executiveComment(entity.getExecutiveComment())
                .executiveApprovedAt(entity.getExecutiveApprovedAt())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
