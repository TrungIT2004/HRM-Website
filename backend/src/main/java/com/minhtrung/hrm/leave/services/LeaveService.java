package com.minhtrung.hrm.leave.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.attendance.enums.AttendanceStatus;
import com.minhtrung.hrm.attendance.repositories.AttendanceRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.leave.dtos.requests.CreateLeaveReqRequest;
import com.minhtrung.hrm.leave.dtos.requests.HandleLeaveReqApiRequest;
import com.minhtrung.hrm.leave.dtos.requests.LeaveFilterRequest;
import com.minhtrung.hrm.leave.dtos.responses.HrLeaveResponse;
import com.minhtrung.hrm.leave.dtos.responses.LeavePreviewResponse;
import com.minhtrung.hrm.leave.dtos.responses.ManagerLeaveResponse;
import com.minhtrung.hrm.leave.dtos.responses.StaffLeaveResponse;
import com.minhtrung.hrm.leave.entities.LeaveRequest;
import com.minhtrung.hrm.leave.enums.LeaveErrorCode;
import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;
import com.minhtrung.hrm.leave.exceptions.LeaveException;
import com.minhtrung.hrm.leave.repositories.LeaveRequestRepository;
import com.minhtrung.hrm.leave.specifications.LeaveRequestSpecification;
import com.minhtrung.hrm.overtime.repositories.HolidayRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class LeaveService {
    private final LeaveRequestRepository leaveRequestRepository;
    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final WorkShiftRepository workShiftRepository;
    private final HolidayRepository holidayRepository;
    private final PermissionService permissionService;

    @Transactional(readOnly = true)
    public LeavePreviewResponse previewLeaveRequest(UUID userId, LocalDate fromDate, LocalDate toDate) {
        if (fromDate == null || toDate == null || fromDate.isAfter(toDate)) {
            throw new LeaveException(LeaveErrorCode.INVALID_LEAVE_DATE,
                    "Ngày bắt đầu nghỉ phải trước hoặc bằng ngày kết thúc");
        }

        // 1. Tính tổng số ngày lịch (tính cả ngày bắt đầu và kết thúc)
        long totalCalendarDays = ChronoUnit.DAYS.between(fromDate, toDate) + 1;

        if (totalCalendarDays > 14) {
            throw new LeaveException(LeaveErrorCode.MAXIMUM_LEAVE_DAYS,
                    "Nhân viên được tạo đơn nghỉ tối đa 14 ngày");
        }

        // 2. Lấy danh sách ngày nghỉ tuần của ca (nếu chưa có ca thì mặc định T7, CN)
        WorkShift usersWorkShift = userRepository.getUsersWorkShift(userId).orElse(null);
        List<Integer> weeklyRestDays = (usersWorkShift != null)
                ? workShiftRepository.getWeeklyRestDays(usersWorkShift.getShiftId())
                : List.of(DayOfWeek.SATURDAY.getValue(), DayOfWeek.SUNDAY.getValue());

        // 3. Lấy danh sách ngày lễ trong khoảng
        List<LocalDate> holidayDates = holidayRepository.getHolidayBetween(fromDate, toDate);

        int restDays = 0;
        int holidayDays = 0;
        int workingDays = 0;

        // 4. Vòng lặp duyệt từng ngày chuẩn xác
        for (LocalDate date = fromDate; !date.isAfter(toDate); date = date.plusDays(1)) {
            if (holidayDates.contains(date)) {
                holidayDays++;
            } else if (weeklyRestDays.contains(date.getDayOfWeek().getValue())) {
                restDays++;
            } else {
                workingDays++;
            }
        }

        // 5. Kiểm tra nếu không có ngày làm việc nào
        if (workingDays == 0) {
            throw new LeaveException(LeaveErrorCode.ALL_REST_DAYS,
                    "Khoảng thời gian nghỉ đều là ngày nghỉ trong lịch làm việc của nhân viên");
        }

        // 6. Lấy thông tin phép năm để Frontend hiển thị đầy đủ
        User user = userRepository.findById(userId).orElseThrow(() ->
                new LeaveException(LeaveErrorCode.USER_NOT_FOUND, "Không tìm thấy nhân viên"));

        int annualLeaveDays = user.getAnnualLeaveDays();
        int usedLeaveDays = user.getUsedLeaveDays();
        int remainingAnnualLeaveDays = annualLeaveDays - usedLeaveDays;

        return LeavePreviewResponse.builder()
                .requestedLeaveDays(totalCalendarDays)
                .workDays(workingDays)
                .restDays(restDays)
                .holidayDays(holidayDays)
                .annualLeaveDays(annualLeaveDays)
                .usedLeaveDays(usedLeaveDays)
                .remainingAnnualLeaveDays(remainingAnnualLeaveDays)
                .remainingAfterThisRequest(Math.max(0, remainingAnnualLeaveDays - workingDays))
                .isSufficientAnnualLeave(remainingAnnualLeaveDays >= workingDays)
                .build();
    }

    @Transactional
    public LeaveRequest createLeaveRequest(CreateLeaveReqRequest request) {
        UUID userId = request.getRequestorId();
        LocalDate fromDate = request.getFromDate();
        LocalDate toDate = request.getToDate();
        String reason = request.getReason();
        int paidLeaveDays = request.getPaidLeaveDays();

        // Chairman là cấp cao nhất: không có ai duyệt được nên đơn tự động ở trạng thái accepted,
        // approver ghi chính Chairman (giữ đúng mốc thời gian ai xử lý).
        boolean isChairman = "Chairman".equals(userRepository.findUsersJob(userId));

        // 1. Tái sử dụng previewLeaveRequest để validate toàn bộ (14 ngày, ngày lễ, ngày nghỉ ca)
        LeavePreviewResponse preview = previewLeaveRequest(userId, fromDate, toDate);

        // 2. Kiểm tra trùng lặp đơn nghỉ phép đang pending hoặc accepted
        boolean isOverlapping = leaveRequestRepository.existsOverlappingLeaveRequest(
                userId, fromDate, toDate, List.of(LeaveRequestStatus.pending, LeaveRequestStatus.accepted));
        if (isOverlapping) {
            throw new LeaveException(LeaveErrorCode.OVERLAPPING_LEAVE_REQUEST,
                    "Khoảng thời gian xin nghỉ phép bị trùng lặp với đơn xin nghỉ phép khác đang chờ duyệt hoặc đã được phê duyệt.");
        }

        // 3. Kiểm tra số ngày xin nghỉ có lương
        if (paidLeaveDays > preview.getWorkDays()) {
            throw new LeaveException(LeaveErrorCode.INVALID_LEAVE_DATE,
                    String.format("Số ngày xin nghỉ có lương (%d ngày) không được vượt quá số ngày làm việc thực tế (%d ngày)",
                            paidLeaveDays, preview.getWorkDays()));
        }

        if (paidLeaveDays > preview.getRemainingAnnualLeaveDays()) {
            throw new LeaveException(LeaveErrorCode.OUT_OF_ANNUAL_LEAVE_DAYS,
                    String.format("Nhân viên chỉ còn %d ngày phép năm, không thể xin %d ngày nghỉ có lương",
                            preview.getRemainingAnnualLeaveDays(), paidLeaveDays));
        }

        // 4. Lưu đơn
        LeaveRequest newLeaveRequest = new LeaveRequest();
        User userProxy = userRepository.getReferenceById(userId);
        newLeaveRequest.setRequestor(userProxy);
        newLeaveRequest.setFromDate(fromDate);
        newLeaveRequest.setToDate(toDate);
        newLeaveRequest.setReason(reason);
        newLeaveRequest.setPaidLeaveDays(paidLeaveDays);

        if (isChairman) {
            newLeaveRequest.setApprover(userProxy);
            newLeaveRequest.setStatus(LeaveRequestStatus.accepted);
        }

        leaveRequestRepository.save(newLeaveRequest);

        if (isChairman) {
            applyAcceptedLeave(newLeaveRequest, userId);
        }

        log.info("Đơn nghỉ phép mới được tạo. RequestorId: {}, Từ ngày: {}, Đến ngày: {}, Số ngày làm việc: {}, Số ngày có lương: {}, Lý do: {}, Tự duyệt: {}",
                userId, fromDate, toDate, preview.getWorkDays(), paidLeaveDays, reason, isChairman);
        return newLeaveRequest;
    }

    @Transactional
    public void cancelLeaveRequest(UUID requestId, UUID currentUserId) {
        LeaveRequest leaveRequest = leaveRequestRepository.findById(requestId).orElseThrow(() ->
                new LeaveException(LeaveErrorCode.REQUEST_NOT_FOUND, "Không tìm thấy yêu cầu nghỉ phép"));

        if (!leaveRequest.getRequestor().getUserId().equals(currentUserId)) {
            throw new LeaveException(LeaveErrorCode.INSUFFICIENT_PERMISSION,
                    "Bạn chỉ có quyền xóa/hủy đơn xin nghỉ phép của chính mình");
        }

        if (!LeaveRequestStatus.pending.equals(leaveRequest.getStatus())) {
            throw new LeaveException(LeaveErrorCode.ALREADY_PROCESSED_REQUEST,
                    "Chỉ có thể xóa/hủy đơn xin nghỉ phép khi đang ở trạng thái chờ duyệt (pending)");
        }

        leaveRequestRepository.delete(leaveRequest);
        log.info("Đơn xin nghỉ phép đã được hủy/xóa thành công. RequestId: {}, RequestorId: {}", requestId, currentUserId);
    }

    @Transactional
    public LeaveRequest handleLeaveRequest(UUID requestId, HandleLeaveReqApiRequest request, UserRole userRole) {
        LeaveRequestStatus status = request.getStatus();

        LeaveRequest leaveRequest = leaveRequestRepository.findById(requestId).orElseThrow(() -> {
            throw new LeaveException(LeaveErrorCode.REQUEST_NOT_FOUND, "Không tìm thấy yêu cầu nghỉ phép");
        });

        if (!leaveRequest.getStatus().equals(LeaveRequestStatus.pending)) {
            throw new LeaveException(LeaveErrorCode.ALREADY_PROCESSED_REQUEST, "Yêu cầu nghỉ phép này đã được xử lý rồi");
        }

        UUID requestorId = leaveRequest.getRequestorId();

        UUID approverId = userRole.getUserId();
        String approverDepartment = userRole.getDepartment();
        String approverJob = userRole.getJob();

        String requestorDepartment = userRepository.findUsersDepartment(requestorId);
        String requesterJob = userRepository.findUsersJob(requestorId);

        if (approverId.equals(requestorId)) {
            throw new LeaveException(LeaveErrorCode.INSUFFICIENT_PERMISSION, "Không thể tự phê duyệt đơn xin nghỉ phép của chính mình");
        }

          boolean isRequestorsDepartmentHead = approverDepartment.equals(requestorDepartment)
                  && approverJob.startsWith("Department Head");
          boolean isExecutive = approverDepartment.equals("Executive Leadership");
          // Grant phòng ban: chỉ duyệt được đơn của chính phòng mình
          boolean canApproveDept = approverDepartment.equals(requestorDepartment)
                  && permissionService.hasPermission(approverId, PermissionKey.LEAVE_APPROVE_DEPT);

        if (requestorDepartment.equals("Executive Leadership")) {
            boolean isDepartmentHead = approverJob.startsWith("Department Head of");
            boolean isDeputyDirector = isExecutive && approverJob.equals("Deputy Director");
            boolean requestorIsExecutive = requestorDepartment.equals("Executive Leadership");
            boolean requestorIsDirector = isExecutive && requesterJob.equals("Director");

            if ((isDeputyDirector && requestorIsDirector) || (isDepartmentHead && requestorIsExecutive)) {
                throw new LeaveException(LeaveErrorCode.INSUFFICIENT_PERMISSION,
                        "Bạn không có thẩm quyền phê duyệt yêu cầu nghỉ phép này");
            }
        }

          if (isRequestorsDepartmentHead || isExecutive || canApproveDept
                  || permissionService.hasPermission(approverId, PermissionKey.LEAVE_APPROVE)) {
            User approverProxy = userRepository.getReferenceById(approverId);

            leaveRequest.setApprover(approverProxy);

            if (status.equals(LeaveRequestStatus.accepted)) {
                applyAcceptedLeave(leaveRequest, requestorId);
            }

            leaveRequest.setStatus(status);
            if (status.equals(LeaveRequestStatus.rejected) && request.getRejectionReason() != null) {
                leaveRequest.setRejectionReason(request.getRejectionReason());
            }

            if (status.equals(LeaveRequestStatus.accepted)) {
                log.info("Đơn nghỉ phép được PHÊ DUYỆT. RequestId: {}, ApproverId: {}, RequestorId: {}, Từ ngày: {}, Đến ngày: {}, Số ngày có lương: {}",
                        requestId, approverId, requestorId, leaveRequest.getFromDate(), leaveRequest.getToDate(), leaveRequest.getPaidLeaveDays());
            } else {
                log.info("Đơn nghỉ phép bị TỪ CHỐI. RequestId: {}, ApproverId: {}, RequestorId: {}, Từ ngày: {}, Đến ngày: {}, Lý do: {}",
                        requestId, approverId, requestorId, leaveRequest.getFromDate(), leaveRequest.getToDate(), leaveRequest.getRejectionReason());
            }

            return leaveRequest;
        } else {
            throw new LeaveException(LeaveErrorCode.INSUFFICIENT_PERMISSION,
                    "Bạn không có thẩm quyền phê duyệt yêu cầu nghỉ phép này");
        }
    }

    /**
     * Side-effect khi một đơn nghỉ phép được ở trạng thái accepted: ghi chấm công
     * PAID_LEAVE/UNPAID_LEAVE cho ngày làm việc thực tế và trừ quỹ phép năm.
     * Dùng chung cho duyệt thủ công (handleLeaveRequest) và duyệt tự động của Chairman.
     */
    private void applyAcceptedLeave(LeaveRequest leaveRequest, UUID requestorId) {
        User requestor = userRepository.findById(requestorId).orElse(null);
        if (requestor == null) {
            return;
        }

        WorkShift shift = userRepository.getUsersWorkShift(requestorId).orElse(null);
        List<Integer> weeklyRestDays = (shift != null)
                ? workShiftRepository.getWeeklyRestDays(shift.getShiftId())
                : List.of(DayOfWeek.SATURDAY.getValue(), DayOfWeek.SUNDAY.getValue());
        List<LocalDate> holidayDates = holidayRepository.getHolidayBetween(leaveRequest.getFromDate(), leaveRequest.getToDate());

        int remainingPaidDays = leaveRequest.getPaidLeaveDays();

        for (LocalDate d = leaveRequest.getFromDate(); !d.isAfter(leaveRequest.getToDate()); d = d.plusDays(1)) {
            boolean isHoliday = holidayDates.contains(d);
            boolean isRestDay = weeklyRestDays.contains(d.getDayOfWeek().getValue());

            // Chỉ cập nhật chấm công nghỉ phép cho các ngày làm việc thực tế
            if (!isHoliday && !isRestDay) {
                AttendanceStatus statusToSet;
                if (remainingPaidDays > 0) {
                    statusToSet = AttendanceStatus.PAID_LEAVE;
                    remainingPaidDays--;
                } else {
                    statusToSet = AttendanceStatus.UNPAID_LEAVE;
                }

                Attendance requestorAttendanceOnLeaveDate = attendanceRepository
                        .findUsersTodayAttendance(requestorId, d).orElse(null);

                if (requestorAttendanceOnLeaveDate != null) {
                    requestorAttendanceOnLeaveDate.setStatus(statusToSet);
                    attendanceRepository.save(requestorAttendanceOnLeaveDate);
                } else {
                    Attendance newRequestorAttendanceOnLeaveDate = new Attendance();
                    User requestorProxy = userRepository.getReferenceById(requestorId);
                    newRequestorAttendanceOnLeaveDate.setUser(requestorProxy);
                    newRequestorAttendanceOnLeaveDate.setShift(shift);
                    newRequestorAttendanceOnLeaveDate.setWorkDate(d);
                    newRequestorAttendanceOnLeaveDate.setStatus(statusToSet);

                    attendanceRepository.save(newRequestorAttendanceOnLeaveDate);
                }
            }
        }

        if (leaveRequest.getPaidLeaveDays() > 0) {
            int annualLeaveDays = requestor.getAnnualLeaveDays();
            int usedLeaveDays = requestor.getUsedLeaveDays();
            requestor.setUsedLeaveDays(Math.min(annualLeaveDays, usedLeaveDays + leaveRequest.getPaidLeaveDays()));
        }
    }

    // 1. Lấy đơn cá nhân
    @Transactional(readOnly = true)
    public Page<StaffLeaveResponse> getMyLeaveRequests(UUID currentUserId, LeaveFilterRequest filter, Pageable pageable) {
        Specification<LeaveRequest> spec = LeaveRequestSpecification.forMyRequests(currentUserId, filter);
        return leaveRequestRepository.findAll(spec, pageable)
            .map(this::mapToStaffResponse);
    }

    // 2. Lấy đơn cần duyệt
    @Transactional(readOnly = true)
    public Page<ManagerLeaveResponse> getLeaveRequestsToApprove(UserRole userRole, LeaveFilterRequest filter, Pageable pageable) {
        boolean hasGrant = permissionService.hasPermission(userRole.getUserId(), PermissionKey.LEAVE_APPROVE);
        boolean hasDeptGrant = permissionService.hasPermission(userRole.getUserId(), PermissionKey.LEAVE_VIEW_DEPT)
                || permissionService.hasPermission(userRole.getUserId(), PermissionKey.LEAVE_APPROVE_DEPT);
        Specification<LeaveRequest> spec = LeaveRequestSpecification.forApprovals(userRole, filter, hasGrant, hasDeptGrant);
        return leaveRequestRepository.findAll(spec, pageable)
            .map(this::mapToManagerResponse);
    }


// 3. Lấy toàn bộ đơn công ty (Chỉ HR được gọi)
    @Transactional(readOnly = true)
    public Page<HrLeaveResponse> getCompanyLeaveRequests(UserRole userRole, LeaveFilterRequest filter, Pageable pageable) {
        String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        if (!myDepartment.equals("Human Resources") && !myDepartment.equals("Executive Leadership")
                && !permissionService.hasPermission(userRole.getUserId(), PermissionKey.LEAVE_VIEW_ALL)) {
            throw new LeaveException(LeaveErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự hoặc Ban Giám Đốc mới có quyền xem các yêu cầu nghỉ phép toàn công ty");
        }

        Specification<LeaveRequest> spec = LeaveRequestSpecification.forCompanyWide(filter);
        return leaveRequestRepository.findAll(spec, pageable)
            .map(this::mapToHrResponse);
    }

    // =================== CÁC HÀM MAP DTO RIÊNG BIỆT ===================

    private StaffLeaveResponse mapToStaffResponse(LeaveRequest entity) {
        User approver = entity.getApprover();
        return StaffLeaveResponse.builder()
            .requestId(entity.getRequestId())
            .fromDate(entity.getFromDate())
            .toDate(entity.getToDate())
            .reason(entity.getReason())
            .rejectionReason(entity.getRejectionReason())
            .paidLeaveDays(entity.getPaidLeaveDays())
            .status(entity.getStatus())
            .createdAt(entity.getCreatedAt())
            .approverId(approver != null ? approver.getUserId() : null)
            .approverName(approver != null ? (approver.getFirstName() + " " + approver.getLastName()) : null)
            .approverJob(approver != null && approver.getJob() != null ? approver.getJob().getTitle() : null)
            .build();
    }

    private ManagerLeaveResponse mapToManagerResponse(LeaveRequest entity) {
        User requestor = entity.getRequestor();
        User approver = entity.getApprover();
        return ManagerLeaveResponse.builder()
            .requestId(entity.getRequestId())
            .fromDate(entity.getFromDate())
            .toDate(entity.getToDate())
            .reason(entity.getReason())
            .paidLeaveDays(entity.getPaidLeaveDays())
            .status(entity.getStatus())
            .createdAt(entity.getCreatedAt())
            .approverId(approver != null ? approver.getUserId() : null)
            .approverName(approver != null ? (approver.getFirstName() + " " + approver.getLastName()) : null)
            .approverJob(approver != null && approver.getJob() != null ? approver.getJob().getTitle() : null)
            .requestorId(requestor != null ? requestor.getUserId() : null)
            .requestorCode(requestor != null ? requestor.getEmployeeCode() : null)
            .requestorName(requestor != null ? (requestor.getFirstName() + " " + requestor.getLastName()) : null)
            .requestorDepartment(
                    requestor != null && requestor.getDepartment() != null ? requestor.getDepartment().getName() : null)
            .requestorJob(requestor != null && requestor.getJob() != null ? requestor.getJob().getTitle() : null)
            .requestorProfilePicUrl(requestor != null ? requestor.getProfilePicUrl() : null)
            .build();
    }
        
    private HrLeaveResponse mapToHrResponse(LeaveRequest entity) {
        User requestor = entity.getRequestor();
        User approver = entity.getApprover();

        int annualDays = (requestor != null) ? requestor.getAnnualLeaveDays() : 0;
        int usedDays = (requestor != null) ? requestor.getUsedLeaveDays() : 0;

        String phoneNumber = (requestor != null && requestor.getProfile() != null)
                ? requestor.getProfile().getPhoneNumber()
                : null;

        return HrLeaveResponse.builder()
                .requestId(entity.getRequestId())
                .fromDate(entity.getFromDate())
                .toDate(entity.getToDate())
                .reason(entity.getReason())
                .paidLeaveDays(entity.getPaidLeaveDays())
                .status(entity.getStatus())
                .createdAt(entity.getCreatedAt())
                .approverId(approver != null ? approver.getUserId() : null)
                .approverName(approver != null ? (approver.getFirstName() + " " + approver.getLastName()) : null)
                .approverJob(approver != null && approver.getJob() != null ? approver.getJob().getTitle() : null)
                .requestorId(requestor != null ? requestor.getUserId() : null)
                .requestorCode(requestor != null ? requestor.getEmployeeCode() : null)
                .requestorName(requestor != null ? (requestor.getFirstName() + " " + requestor.getLastName()) : null)
                .requestorDepartment(
                        requestor != null && requestor.getDepartment() != null ? requestor.getDepartment().getName()
                                : null)
                .requestorJob(requestor != null && requestor.getJob() != null ? requestor.getJob().getTitle() : null)
                .requestorProfilePicUrl(requestor != null ? requestor.getProfilePicUrl() : null)
                .totalAnnualLeaveDays(annualDays)
                .usedLeaveDays(usedDays)
                .remainingAnnualLeaveDays(annualDays - usedDays)
                .requestorEmail(requestor != null ? requestor.getEmail() : null)
                .requestorPhoneNumber(phoneNumber)
                .build();
    }
    
    // ─── XUẤT EXCEL NGHỈ PHÉP TOÀN CÔNG TY (HR) ───────────────────────
    @Transactional(readOnly = true)
    public byte[] exportLeaveRequestsToExcel(UserRole userRole, LeaveFilterRequest filter) {
        String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        if (!myDepartment.equals("Human Resources") && !myDepartment.equals("Executive Leadership")
                && !permissionService.hasPermission(userRole.getUserId(), PermissionKey.LEAVE_VIEW_ALL)) {
                throw new LeaveException(LeaveErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự hoặc Ban Giám Đốc mới có quyền xuất báo cáo nghỉ phép");
        }

        // 1. Lấy toàn bộ danh sách đơn nghỉ phép theo bộ lọc
        Specification<LeaveRequest> spec = LeaveRequestSpecification.forCompanyWide(filter);
        List<LeaveRequest> leaveRequests = leaveRequestRepository.findAll(spec, Sort.by(Sort.Direction.DESC, "fromDate"));
        List<HrLeaveResponse> dtoList = leaveRequests.stream().map(this::mapToHrResponse).toList();

        // 2. Ghi ra file Excel
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                Sheet sheet = workbook.createSheet("Danh Sach Nghi Phep");
                sheet.setDisplayGridlines(false);
                final int OFF = 1;
                sheet.setColumnWidth(0, 6 * 256);

                // Header Style (TNR đậm, nền xanh đậm chữ trắng, căn giữa)
                CellStyle headerStyle = workbook.createCellStyle();
                Font headerFont = workbook.createFont();
                headerFont.setBold(true);
                headerFont.setFontName("Times New Roman");
                headerFont.setColor(IndexedColors.WHITE.getIndex());
                headerStyle.setFont(headerFont);
                headerStyle.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
                headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
                headerStyle.setAlignment(HorizontalAlignment.CENTER);
                headerStyle.setVerticalAlignment(VerticalAlignment.CENTER);

                CellStyle bordered = workbook.createCellStyle();
                bordered.setBorderTop(BorderStyle.THIN);
                bordered.setBorderBottom(BorderStyle.THIN);
                bordered.setBorderLeft(BorderStyle.THIN);
                bordered.setBorderRight(BorderStyle.THIN);
                bordered.setIndention((short) 1);
                bordered.setVerticalAlignment(VerticalAlignment.CENTER);
                Font bodyFont = workbook.createFont();
                bodyFont.setFontName("Times New Roman");
                bordered.setFont(bodyFont);

                String[] columns = {
                                "STT", "Mã NV", "Họ và Tên", "Phòng Ban", "Chức Vụ",
                                "Từ Ngày", "Đến Ngày", "Số Ngày Có Lương", "Lý Do", "Trạng Thái",
                                "Người Duyệt", "Phép Năm Đã Dùng", "Tổng Phép Năm"
                };

                int rowIdx = 3;
                Row headerRow = sheet.createRow(rowIdx++);
                headerRow.setHeightInPoints(28);
                for (int i = 0; i < columns.length; i++) {
                        Cell cell = headerRow.createCell(OFF + i);
                        cell.setCellValue(columns[i]);
                        cell.setCellStyle(headerStyle);
                }

                int stt = 1;
                for (HrLeaveResponse rowData : dtoList) {
                        Row row = sheet.createRow(rowIdx++);
                        row.setHeightInPoints(28);

                        row.createCell(OFF + 0).setCellValue(stt++);
                        row.createCell(OFF + 1).setCellValue(rowData.getRequestorCode() != null ? rowData.getRequestorCode() : "");
                        row.createCell(OFF + 2).setCellValue(rowData.getRequestorName() != null ? rowData.getRequestorName() : "");
                        row.createCell(OFF + 3)
                                        .setCellValue(rowData.getRequestorDepartment() != null ? rowData.getRequestorDepartment() : "");
                        row.createCell(OFF + 4).setCellValue(rowData.getRequestorJob() != null ? rowData.getRequestorJob() : "");
                        row.createCell(OFF + 5).setCellValue(rowData.getFromDate() != null ? rowData.getFromDate().toString() : "");
                        row.createCell(OFF + 6).setCellValue(rowData.getToDate() != null ? rowData.getToDate().toString() : "");
                        row.createCell(OFF + 7)
                                        .setCellValue(rowData.getPaidLeaveDays() > 0 ? (rowData.getPaidLeaveDays() + " ngày có lương") : "Không lương");
                        row.createCell(OFF + 8).setCellValue(rowData.getReason() != null ? rowData.getReason() : "");
                        row.createCell(OFF + 9).setCellValue(leaveStatusVi(rowData.getStatus()));
                        row.createCell(OFF + 10).setCellValue(rowData.getApproverName() != null ? rowData.getApproverName() : "");
                        row.createCell(OFF + 11).setCellValue(rowData.getUsedLeaveDays() != null ? rowData.getUsedLeaveDays() : 0);
                        row.createCell(OFF + 12).setCellValue(rowData.getTotalAnnualLeaveDays() != null ? rowData.getTotalAnnualLeaveDays() : 0);
                        for (int i = 0; i < columns.length; i++) {
                                row.getCell(OFF + i).setCellStyle(bordered);
                        }
                }

                for (int i = 0; i < columns.length; i++) {
                        sheet.autoSizeColumn(OFF + i);
                }
                sheet.setColumnWidth(OFF, 8 * 256);

                Row titleRow = sheet.createRow(0);
                Cell titleCell = titleRow.createCell(OFF + 4);
                titleCell.setCellValue("BẢNG TỔNG HỢP ĐƠN NGHỈ PHÉP");
                CellStyle titleStyle = workbook.createCellStyle();
                Font titleFont = workbook.createFont();
                titleFont.setBold(true);
                titleFont.setFontName("Times New Roman");
                titleFont.setFontHeightInPoints((short) 22);
                titleFont.setColor(IndexedColors.DARK_BLUE.getIndex());
                titleStyle.setFont(titleFont);
                titleCell.setCellStyle(titleStyle);

                workbook.write(out);
                return out.toByteArray();
        } catch (IOException e) {
                log.error("Failed to generate Leave Request Excel file", e);
                throw new LeaveException(LeaveErrorCode.INTERNAL_SERVER_ERROR, "Đã xảy ra lỗi trong quá trình xuất báo cáo nghỉ phép Excel");
        }
    }

    private String leaveStatusVi(Object status) {
        if (status == null) return "";
        return switch (status.toString().toLowerCase()) {
            case "accepted" -> "Đã duyệt";
            case "rejected" -> "Từ chối";
            default -> "Chờ duyệt";
        };
    }

}
