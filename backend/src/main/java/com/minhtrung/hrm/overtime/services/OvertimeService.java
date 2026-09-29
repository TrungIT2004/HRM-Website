package com.minhtrung.hrm.overtime.services;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.apache.poi.ss.usermodel.*;
import org.springframework.data.domain.Sort;

import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.attendance.entities.WorkShiftSchedule;
import com.minhtrung.hrm.attendance.repositories.WorkShiftScheduleRepository;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.overtime.dtos.requests.HandleOvertimeReqApiRequest;
import com.minhtrung.hrm.overtime.dtos.requests.OvertimeFilterRequest;
import com.minhtrung.hrm.overtime.dtos.requests.OvertimeWorkTimeRequest;
import com.minhtrung.hrm.overtime.dtos.responses.HrOvertimeResponse;
import com.minhtrung.hrm.overtime.dtos.responses.ManagerOvertimeResponse;
import com.minhtrung.hrm.overtime.dtos.responses.StaffOvertimeResponse;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.enums.OvertimeErrorCode;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;
import com.minhtrung.hrm.overtime.exceptions.OvertimeException;
import com.minhtrung.hrm.overtime.repositories.HolidayRepository;
import com.minhtrung.hrm.attendance.entities.WorkShiftSchedule;
import com.minhtrung.hrm.attendance.services.AttendanceService;
import com.minhtrung.hrm.overtime.dtos.responses.OvertimePreviewResponse;
import com.minhtrung.hrm.overtime.repositories.OvertimeRecordRepository;
import com.minhtrung.hrm.overtime.specification.OvertimeSpecification;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class OvertimeService {

    private final OvertimeRecordRepository overtimeRecordRepository;
    private final UserRepository userRepository;
    private final HolidayRepository holidayRepository;
    private final WorkShiftScheduleRepository workShiftScheduleRepository;
    private final PermissionService permissionService;

    /**
     * Xem trước thời gian + hệ số OT. Tái dùng đúng luật đang áp dụng khi lưu đơn:
     * OvertimeRecord.setFlags() (cuối tuần / ban đêm) + calcOvertimeAmounts() (hệ số theo ngày lễ).
     * Frontend không tự tính lại để tránh lệch với bảng lương.
     */
    @Transactional(readOnly = true)
    public OvertimePreviewResponse previewOvertime(LocalDateTime start, LocalDateTime end) {
        LocalDateTime resolvedEnd = resolveEnd(start, end);
        double hours = Duration.between(start, resolvedEnd).toMinutes() / 60.0;

        OvertimeRecord probe = new OvertimeRecord();
        probe.setApprovedStartTime(start);
        probe.setApprovedEndTime(resolvedEnd);
        probe.setFlags();
        probe.setHoliday(isAnyDayHoliday(start, resolvedEnd));

        double multiplier = 0.0;
        if (hours > 0) {
            multiplier = AttendanceService.calcOvertimeAmounts(probe).multiplier();
        }

        return new OvertimePreviewResponse(
                resolvedEnd.toLocalDate().equals(start.toLocalDate()) ? null : resolvedEnd.toLocalDate(),
                hours,
                probe.isWeekend(),
                probe.isHoliday(),
                probe.isNightTime(),
                multiplier,
                hours * multiplier);
    }

    // ─── LẤY SCHEDULE ────────────────────────────────────────────────
    private WorkShiftSchedule getScheduleOrNull(UUID shiftId, LocalDate date) {
        int dayOfWeek = date.getDayOfWeek().getValue();
        return workShiftScheduleRepository
                .findByWorkShift_ShiftIdAndDayOfWeek(shiftId, dayOfWeek)
                .orElse(null);
    }

    // ─── TÍNH GIỜ LÀM THỰC TẾ ───────────────────────────────────────
    private double calculateWorkTime(WorkShiftSchedule schedule) {
        if (schedule == null || !schedule.isWorking()) {
            return 0.0;
        }

        double total = Duration.between(schedule.getStartTime(), schedule.getEndTime()).toMinutes() / 60.0;

        if (schedule.getRestStartTime() != null && schedule.getRestEndTime() != null) {
            double rest = Duration.between(schedule.getRestStartTime(), schedule.getRestEndTime()).toMinutes() / 60.0;
            return total - rest;
        }
        return total;
    }

    // ─── KIỂM TRA NẰM TRONG GIỜ LÀM ─────────────────────────────────
    private boolean isWithinWorkingHours(LocalDateTime time, WorkShiftSchedule schedule) {
        if (schedule == null || !schedule.isWorking() || holidayRepository.existsByDate(time.toLocalDate())) {
            return false;
        }
        LocalTime timeOfDay = time.toLocalTime();
        return timeOfDay.isAfter(schedule.getStartTime()) && timeOfDay.isBefore(schedule.getEndTime());
    }

    // ─── VALIDATE GIỚI HẠN NGÀY ──────────────────────────────────────
    public void validateDayLimit(double totalOTHours, WorkShiftSchedule workShiftSchedule) {
        double workTime = calculateWorkTime(workShiftSchedule);

        if (workTime == 0) {
            return;
        }

        if (totalOTHours + workTime > 12) {
            log.warn("User exceeds daily 12h total: work={}h, OT={}h", workTime, totalOTHours);
            throw new OvertimeException(OvertimeErrorCode.EXCEED_DAILY_TOTAL,
                    String.format("Tổng thời gian làm việc (ca thường + tăng ca) vượt quá 12 giờ một ngày. Ca thường: %.1fh, OT: %.1fh",
                            workTime, totalOTHours));
        }

        if (totalOTHours > 0.5 * workTime) {
            log.warn("OT exceeds 50%% of work time: work={}h, OT={}h, max OT={}h",
                    workTime, totalOTHours, 0.5 * workTime);
            throw new OvertimeException(OvertimeErrorCode.EXCEED_50_PERCENT,
                    String.format("Giờ tăng ca không được vượt quá 50%% số giờ làm việc bình thường. Giờ thường: %.1fh, OT: %.1fh, tối đa cho phép: %.1fh",
                            workTime, totalOTHours, 0.5 * workTime));
        }
    }

    // ─── VALIDATE THEO TỪNG NGÀY ─────────────────────────────────────
    private void validateDailyOvertimeLimits(LocalDateTime start, LocalDateTime end, UUID shiftId) {
        LocalDate startDate = start.toLocalDate();
        LocalDate endDate = end.toLocalDate();

        if (startDate.equals(endDate)) {
            double totalOT = Duration.between(start, end).toMinutes() / 60.0;
            WorkShiftSchedule schedule = getScheduleOrNull(shiftId, startDate);
            validateDayLimit(totalOT, schedule);
        } else {
            // Ngày bắt đầu
            LocalDateTime endOfStartDay = startDate.atStartOfDay().plusDays(1);
            double firstDayOT = Duration.between(start, endOfStartDay).toMinutes() / 60.0;
            WorkShiftSchedule startSchedule = getScheduleOrNull(shiftId, startDate);
            validateDayLimit(firstDayOT, startSchedule);

            // Ngày kết thúc
            LocalDateTime startOfEndDay = endDate.atStartOfDay();
            double secondDayOT = Duration.between(startOfEndDay, end).toMinutes() / 60.0;
            WorkShiftSchedule endSchedule = getScheduleOrNull(shiftId, endDate);
            validateDayLimit(secondDayOT, endSchedule);
        }
    }

    // ─── TẠO ĐƠN TĂNG CA ─────────────────────────────────────────────
    /**
     * Chuẩn hoá cửa sổ OT: giờ kết thúc <= giờ bắt đầu nghĩa là làm xuyên đêm
     * → kéo giờ kết thúc sang ngày hôm sau. Dùng chung cho preview và create
     * để UI và DB luôn thống nhất.
     */
    public static LocalDateTime resolveEnd(LocalDateTime start, LocalDateTime end) {
        return end.isAfter(start) ? end : end.plusDays(1);
    }

    @Transactional
    public OvertimeRecord createOvertimeRequest(UUID requestorId, OvertimeWorkTimeRequest req) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start = req.getApprovedStartTime();
        // Ca xuyên đêm (vd 18:00 -> 01:00) phải tính sang ngày hôm sau, nếu không Duration.between ra số âm
        LocalDateTime end = resolveEnd(start, req.getApprovedEndTime());
        LocalDate OTStartDate = start.toLocalDate();
        LocalDate OTEndDate = end.toLocalDate();
        double restTime = 0.0;

        if (start.isBefore(now)) {
            throw new OvertimeException(OvertimeErrorCode.INVALID_TIME, "Ngày làm việc đã trôi qua. Không thể đăng ký làm thêm giờ cho quá khứ");
        }

        double requestedHours = Duration.between(start, end).toMinutes() / 60.0;

        if (requestedHours < 1) {
            throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_TIME, "Thời gian làm thêm giờ phải ít nhất 1 giờ");
        }

        // 1. Tổng OT không được quá 12h
        if (requestedHours > 12) {
            log.warn("User {} requested OT {}h exceeds 12h limit", requestorId, requestedHours);
            throw new OvertimeException(OvertimeErrorCode.EXCEED_MAXIMUM_OVERTIME,
                    String.format("Tổng thời gian tăng ca cho một yêu cầu đơn lẻ không được vượt quá 12 giờ. Đã yêu cầu: %.1f giờ.",
                            requestedHours));
        }

        // 2. Lấy ca làm việc của nhân viên
        WorkShift requestorsWorkShift = userRepository.getUsersWorkShift(requestorId)
                .orElseThrow(() -> {
                    log.error("User {} has no work shift assigned", requestorId);
                    return new OvertimeException(OvertimeErrorCode.USER_NO_SHIFT,
                            "Không tìm thấy ca làm việc được phân công cho nhân viên này. Vui lòng liên hệ phòng Nhân sự.");
                });
        UUID shiftId = requestorsWorkShift.getShiftId();

        WorkShiftSchedule startSchedule = getScheduleOrNull(shiftId, OTStartDate);
        WorkShiftSchedule endSchedule = getScheduleOrNull(shiftId, OTEndDate);

        // 3. Kiểm tra chồng lấn với giờ làm việc
        if (OTStartDate.isEqual(OTEndDate)) {
            if (isWithinWorkingHours(start, endSchedule) || isWithinWorkingHours(end, endSchedule)) {
                log.warn("User {} OT {} - {} overlaps regular working hours on {}", requestorId, start, end, OTStartDate);
                throw new OvertimeException(OvertimeErrorCode.OVERLAP_WORK_HOURS,
                        String.format("Thời gian làm thêm bị trùng với ca làm việc chính thức vào ngày %s. Ca chính thức: %s - %s.",
                                  OTStartDate,
                                  endSchedule != null ? endSchedule.getStartTime() : "??",
                                  endSchedule != null ? endSchedule.getEndTime() : "??"));
            }
        } else {
            if (isWithinWorkingHours(start, startSchedule) || isWithinWorkingHours(end, endSchedule)) {
                log.warn("User {} OT {} - {} overlaps regular working hours on start or end date", requestorId, start, end);
                throw new OvertimeException(OvertimeErrorCode.OVERLAP_WORK_HOURS,
                        "Thời gian làm thêm giờ không được trùng lặp với giờ làm việc chính thức.");
            }
        }

        // 4. Kiểm tra nghỉ ít nhất 12h giữa các ca
        if (endSchedule != null && endSchedule.isWorking()) {
            LocalDateTime shiftStartDate = LocalDateTime.of(OTEndDate, endSchedule.getStartTime());

            if (!end.isAfter(shiftStartDate)) {
                // end <= giờ bắt đầu ca (ví dụ 08:00)
                restTime = Duration.between(end, shiftStartDate).toHours();
            } else {
                // end > giờ bắt đầu ca -> ca tiếp theo là ngày mai
                LocalDateTime nextDayShiftStart = shiftStartDate.plusDays(1);
                restTime = Duration.between(end, nextDayShiftStart).toHours();
            }
        } else {
            WorkShiftSchedule nextDayShiftSchedule = getScheduleOrNull(shiftId, OTEndDate.plusDays(1));

            if (nextDayShiftSchedule != null && nextDayShiftSchedule.isWorking()) {
                LocalDateTime nextDayShiftStartDate = LocalDateTime.of(OTEndDate.plusDays(1),
                        nextDayShiftSchedule.getStartTime());
                restTime = Duration.between(end, nextDayShiftStartDate).toHours();
            } else {
                restTime = 24; // an toàn vì > 12h
            }
        }

        if (restTime < 12) {
            log.warn("User {} has only {}h rest between {} and next shift", requestorId, restTime, end);
            throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_REST,
                    String.format("Không đủ thời gian nghỉ ngơi giữa các ca. Quy định tối thiểu là 12 giờ nghỉ, thực tế: %.1f giờ.",
                            restTime));
        }

        // 5. Kiểm tra giới hạn 12h/50% theo từng ngày
        validateDailyOvertimeLimits(start, end, shiftId);

        // 6. Giới hạn tháng (40h)
        LocalDateTime monthStart = OTStartDate.withDayOfMonth(1).atStartOfDay();
        LocalDateTime monthEnd = OTStartDate.withDayOfMonth(OTStartDate.lengthOfMonth())
                .atTime(23, 59, 59, 999999999);

        double monthTotal = overtimeRecordRepository.getTotalOvertimeHoursBetween(requestorId, monthStart, monthEnd);
        if (monthTotal + requestedHours > 40) {
            log.warn("User {} exceeds monthly OT limit: {} + {} > 40", requestorId, monthTotal, requestedHours);
            throw new OvertimeException(OvertimeErrorCode.EXCEED_MONTHLY_OVERTIME,
                    String.format("Vượt quá giới hạn làm thêm giờ trong tháng. Tối đa 40 giờ. Đã dùng: %.1fh, yêu cầu: %.1fh.",
                            monthTotal, requestedHours));
        }

        // 7. Giới hạn năm (200h)
        LocalDateTime yearStart = LocalDate.of(OTStartDate.getYear(), 1, 1).atStartOfDay();
        LocalDateTime yearEnd = LocalDate.of(OTStartDate.getYear(), 12, 31)
                .atTime(23, 59, 59, 999999999);

        double yearTotal = overtimeRecordRepository.getTotalOvertimeHoursBetween(requestorId, yearStart, yearEnd);
        if (yearTotal + requestedHours > 200) {
            log.warn("User {} exceeds yearly OT limit: {} + {} > 200", requestorId, yearTotal, requestedHours);
            throw new OvertimeException(OvertimeErrorCode.EXCEED_YEARLY_OVERTIME,
                    String.format("Vượt quá giới hạn làm thêm giờ trong năm. Tối đa 200 giờ. Đã dùng: %.1fh, yêu cầu lầm thêm: %.1fh.",
                            yearTotal, requestedHours));
        }

        // 8. Kiểm tra ngày lễ
        boolean isHoliday = isAnyDayHoliday(start, end);

        // 9. Lưu đơn
        User userProxy = userRepository.getReferenceById(requestorId);
        OvertimeRecord record = new OvertimeRecord();
        record.setRequestor(userProxy);
        record.setApprovedDate(OTStartDate);
        record.setApprovedStartTime(start);
        record.setApprovedEndTime(end);
        record.setHoliday(isHoliday);
        record.setReason(req.getReason());

        // Chairman là cấp cao nhất: không có ai duyệt được nên đơn tự động ở trạng thái accepted,
        // approver ghi chính Chairman (giữ đúng mốc thời gian ai xử lý).
        boolean isChairman = "Chairman".equals(userRepository.findUsersJob(requestorId));
        if (isChairman) {
            record.setApprover(userProxy);
            record.setStatus(OvertimeRecordStatus.accepted);
        }

        OvertimeRecord saved = overtimeRecordRepository.save(record);
        log.info("Đơn tăng ca mới được tạo. RequestorId: {}, Thời gian bắt đầu: {}, Thời gian kết thúc: {}, Ngày lễ: {}, Số giờ đăng ký: {}, Tự duyệt: {}",
                requestorId, start, end, isHoliday, String.format("%.1f", requestedHours), isChairman);
        return saved;
    }

    // ─── KIỂM TRA NGÀY LỄ ────────────────────────────────────────────
    private boolean isAnyDayHoliday(LocalDateTime start, LocalDateTime end) {
        LocalDateTime current = start;
        while (current.isBefore(end)) {
            LocalDate date = current.toLocalDate();
            if (holidayRepository.existsByDate(date)) {
                return true;
            }
            current = date.plusDays(1).atStartOfDay();
        }
        return false;
    }

    public String checkOTAttenndance(UUID userId) {
        LocalDate now = LocalDate.now();
        LocalDateTime clockingTime = LocalDateTime.now();

        OvertimeRecord overtimeRecord = overtimeRecordRepository.findByRequestorIdAndApprovedDateAndStatus(userId, now,
                OvertimeRecordStatus.accepted).orElseThrow(() -> {
                    throw new OvertimeException(OvertimeErrorCode.RECORD_NOT_FOUND,
                            "Hôm nay bạn không có lịch hoặc yêu cầu tăng ca (OT) nào được phê duyệt.");
                });

        LocalDateTime clockInTime = overtimeRecord.getClockInTime();
        LocalDateTime clockOutTime = overtimeRecord.getClockOutTime();

        boolean clockInTurn = clockInTime == null && clockOutTime == null;
        boolean clockOutTurn = clockInTime != null && clockOutTime == null;
        boolean isAlreadyClockedOut = clockInTime != null && clockOutTime != null;

        if (clockInTurn) {
            overtimeRecord.setClockInTime(clockingTime);
            log.info("OT CLOCK_IN thành công. UserId: {}, RecordId: {}, Thời gian: {}", userId, overtimeRecord.getOvertimeRecordId(), clockingTime);
            return "CLOCK_IN";
        }
        
        if (clockOutTurn) {
            boolean hasWorkedOTForAtLeastAmmountOfTime = Duration.between(clockInTime, clockingTime).toMinutes() >= 60;

            if (hasWorkedOTForAtLeastAmmountOfTime) {
                overtimeRecord.setClockOutTime(clockingTime);
                log.info("OT CLOCK_OUT thành công. UserId: {}, RecordId: {}, Thời gian: {}, Thời gian OT: {} phút",
                        userId, overtimeRecord.getOvertimeRecordId(), clockingTime,
                        Duration.between(clockInTime, clockingTime).toMinutes());
                return "CLOCK_OUT";
            } else {
                throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_OT_TIME, "Thời gian làm việc tăng ca phải đạt tối thiểu 1 giờ");
            }
        }

        if (isAlreadyClockedOut) {
            overtimeRecord.setClockOutTime(clockingTime);
            log.info("OT CLOCK_OUT (ghi đè). UserId: {}, RecordId: {}, Thời gian: {}", userId, overtimeRecord.getOvertimeRecordId(), clockingTime);
            return "CLOCK_OUT";
        }

        return "UNKNOWN";

    }

    // ─── XỬ LÝ DUYỆT / TỪ CHỐI ĐƠN TĂNG CA ───────────────────────────
    @Transactional
    public OvertimeRecord handleOvertimeRequest(UUID overtimeRecordId, HandleOvertimeReqApiRequest request, UserRole userRole) {
        OvertimeRecordStatus targetStatus = request.getStatus();

        // 1. Tìm đơn OT
        OvertimeRecord overtimeRecord = overtimeRecordRepository.findById(overtimeRecordId)
                .orElseThrow(() -> new OvertimeException(OvertimeErrorCode.RECORD_NOT_FOUND, "Không tìm thấy yêu cầu làm thêm giờ"));

        // 2. Kiểm tra trạng thái đơn hiện tại (chỉ được xử lý khi đang ở trạng thái pending)
        if (!OvertimeRecordStatus.pending.equals(overtimeRecord.getStatus())) {
            throw new OvertimeException(OvertimeErrorCode.ALREADY_PROCESSED_REQUEST, "Yêu cầu làm thêm giờ đã được xử lý trước đó");
        }

        UUID requestorId = overtimeRecord.getRequestor().getUserId();
        UUID approverId = userRole.getUserId();
        String approverDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        String approverJob = userRole.getJob() != null ? userRole.getJob() : "";

        // 3. Không được tự duyệt đơn của chính mình
        if (approverId.equals(requestorId)) {
            throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_PERMISSION, "Không thể tự phê duyệt đơn làm thêm giờ của bản thân");
        }

        String requestorDepartment = userRepository.findUsersDepartment(requestorId);
        String requesterJob = userRepository.findUsersJob(requestorId);

        boolean isRequestorsDepartmentHead = approverDepartment.equals(requestorDepartment)
                && approverJob.startsWith("Department Head");
        boolean isExecutive = approverDepartment.equals("Executive Leadership");

        // 4. Kiểm tra quyền phê duyệt theo phân cấp
        if ("Executive Leadership".equals(requestorDepartment)) {
            boolean isDepartmentHead = approverJob.startsWith("Department Head");
            boolean isDeputyDirector = isExecutive && (approverJob.contains("Deputy") || approverJob.contains("Vice"));
            boolean requestorIsDirector = "Director".equalsIgnoreCase(requesterJob);
            boolean requestorIsChairman = "Chairman".equalsIgnoreCase(requesterJob);

            // Phó GĐ không duyệt Giám đốc/Chủ tịch; Trưởng phòng không duyệt Ban Giám Đốc
            if ((isDeputyDirector && (requestorIsDirector || requestorIsChairman)) || isDepartmentHead) {
                throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_PERMISSION,
                        "Bạn không có thẩm quyền phê duyệt yêu cầu tăng ca này");
            }
        }

        if (isRequestorsDepartmentHead || isExecutive
                || permissionService.hasPermission(userRole.getUserId(), PermissionKey.OVERTIME_APPROVE)) {
            // 5. Gán người duyệt và cập nhật trạng thái mới
            User approverProxy = userRepository.getReferenceById(approverId);
            overtimeRecord.setApprover(approverProxy);
            overtimeRecord.setStatus(targetStatus);
            if (OvertimeRecordStatus.rejected.equals(targetStatus) && request.getRejectionReason() != null) {
                overtimeRecord.setRejectionReason(request.getRejectionReason());
            }

            if (OvertimeRecordStatus.accepted.equals(targetStatus)) {
                log.info("Đơn tăng ca được PHÊ DUYỆT. RecordId: {}, ApproverId: {}, RequestorId: {}",
                        overtimeRecordId, approverId, requestorId);
            } else {
                log.info("Đơn tăng ca bị TỪ CHỐI. RecordId: {}, ApproverId: {}, RequestorId: {}, Lý do: {}",
                        overtimeRecordId, approverId, requestorId, overtimeRecord.getRejectionReason());
            }
            return overtimeRecord;
        } else {
            throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_PERMISSION,
                    "Bạn không có thẩm quyền phê duyệt yêu cầu làm thêm giờ");
        }
    }

    // ─── HỦY ĐƠN TĂNG CA (KHI ĐANG PENDING) ──────────────────────────
    @Transactional
    public void cancelOvertimeRequest(UUID requestorId, UUID overtimeRecordId) {
        OvertimeRecord record = overtimeRecordRepository.findById(overtimeRecordId).orElseThrow(() ->
                new OvertimeException(OvertimeErrorCode.RECORD_NOT_FOUND, "Không tìm thấy yêu cầu làm thêm giờ"));

        if (!record.getRequestor().getUserId().equals(requestorId)) {
            throw new OvertimeException(OvertimeErrorCode.NOT_RECORD_OWNER, "Bạn chỉ có thể hủy đơn làm thêm giờ của chính mình");
        }

        if (!OvertimeRecordStatus.pending.equals(record.getStatus())) {
            throw new OvertimeException(OvertimeErrorCode.CANNOT_CANCEL_NON_PENDING, "Chỉ có thể hủy đơn làm thêm giờ khi ở trạng thái chờ duyệt (pending)");
        }

        overtimeRecordRepository.delete(record);
        log.info("Hủy đơn làm thêm giờ thành công. RecordId: {}, RequestorId: {}", overtimeRecordId, requestorId);
    }

    // ─── XEM ĐƠN OT CÁ NHÂN ─────────────────────────────────────────
    @Transactional(readOnly = true)
    public Page<StaffOvertimeResponse> getMyOvertimeRecords(UUID currentUserId, OvertimeFilterRequest filter, Pageable pageable) {
        Specification<OvertimeRecord> spec = OvertimeSpecification.forMyRecords(currentUserId, filter);
        return overtimeRecordRepository.findAll(spec, pageable).map(this::mapToStaffResponse);
    }

    // ─── XEM ĐƠN OT CẦN PHÊ DUYỆT ───────────────────────────────────
    @Transactional(readOnly = true)
    public Page<ManagerOvertimeResponse> getOvertimeRecordsToApprove(UserRole userRole, OvertimeFilterRequest filter, Pageable pageable) {
        boolean hasGrant = permissionService.hasPermission(userRole.getUserId(), PermissionKey.OVERTIME_APPROVE);
        Specification<OvertimeRecord> spec = OvertimeSpecification.forApprovals(userRole, filter, hasGrant);
        return overtimeRecordRepository.findAll(spec, pageable).map(this::mapToManagerResponse);
    }

    // ─── XEM ĐƠN OT TOÀN CÔNG TY (HR) ──────────────────────────────
    @Transactional(readOnly = true)
    public Page<HrOvertimeResponse> getCompanyOvertimeRecords(UserRole userRole, OvertimeFilterRequest filter, Pageable pageable) {
        String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        if (!myDepartment.equals("Human Resources") && !myDepartment.equals("Executive Leadership")
                && !permissionService.hasPermission(userRole.getUserId(), PermissionKey.OVERTIME_VIEW_ALL)) {
            throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự hoặc Ban Giám Đốc mới có quyền xem toàn bộ bản ghi tăng ca công ty");
        }

        Specification<OvertimeRecord> spec = OvertimeSpecification.forCompanyWide(filter);
        return overtimeRecordRepository.findAll(spec, pageable).map(this::mapToHrResponse);
    }

    // ─── MAPPING HELPER METHODS ──────────────────────────────────────

    private StaffOvertimeResponse mapToStaffResponse(OvertimeRecord entity) {
        User approver = entity.getApprover();
        return StaffOvertimeResponse.builder()
                .overtimeRecordId(entity.getOvertimeRecordId())
                .approvedDate(entity.getApprovedDate())
                .approvedStartTime(entity.getApprovedStartTime())
                .approvedEndTime(entity.getApprovedEndTime())
                .clockInTime(entity.getClockInTime())
                .clockOutTime(entity.getClockOutTime())
                .isHoliday(entity.isHoliday())
                .isWeekend(entity.isWeekend())
                .isNightTime(entity.isNightTime())
                .status(entity.getStatus())
                .reason(entity.getReason())
                .rejectionReason(entity.getRejectionReason())
                .approverId(approver != null ? approver.getUserId() : null)
                .approverName(approver != null ? (approver.getFirstName() + " " + approver.getLastName()) : null)
                .approverJob(approver != null && approver.getJob() != null ? approver.getJob().getTitle() : null)
                .build();
    }

    private ManagerOvertimeResponse mapToManagerResponse(OvertimeRecord entity) {
        User requestor = entity.getRequestor();
        User approver = entity.getApprover();
        return ManagerOvertimeResponse.builder()
                .overtimeRecordId(entity.getOvertimeRecordId())
                .approvedDate(entity.getApprovedDate())
                .approvedStartTime(entity.getApprovedStartTime())
                .approvedEndTime(entity.getApprovedEndTime())
                .clockInTime(entity.getClockInTime())
                .clockOutTime(entity.getClockOutTime())
                .isHoliday(entity.isHoliday())
                .isWeekend(entity.isWeekend())
                .isNightTime(entity.isNightTime())
                .status(entity.getStatus())
                .approverId(approver != null ? approver.getUserId() : null)
                .approverName(approver != null ? (approver.getFirstName() + " " + approver.getLastName()) : null)
                .approverJob(approver != null && approver.getJob() != null ? approver.getJob().getTitle() : null)
                .requestorId(requestor != null ? requestor.getUserId() : null)
                .requestorCode(requestor != null ? requestor.getEmployeeCode() : null)
                .requestorName(requestor != null ? (requestor.getFirstName() + " " + requestor.getLastName()) : null)
                .requestorDepartment(requestor != null && requestor.getDepartment() != null ? requestor.getDepartment().getName() : null)
                .requestorJob(requestor != null && requestor.getJob() != null ? requestor.getJob().getTitle() : null)
                .requestorProfilePicUrl(requestor != null ? requestor.getProfilePicUrl() : null)
                .build();
    }

    private HrOvertimeResponse mapToHrResponse(OvertimeRecord entity) {
        User requestor = entity.getRequestor();
        User approver = entity.getApprover();

        Double approvedHours = (entity.getApprovedStartTime() != null && entity.getApprovedEndTime() != null)
                ? Duration.between(entity.getApprovedStartTime(), entity.getApprovedEndTime()).toMinutes() / 60.0
                : 0.0;

        Double actualHours = (entity.getClockInTime() != null && entity.getClockOutTime() != null)
                ? Duration.between(entity.getClockInTime(), entity.getClockOutTime()).toMinutes() / 60.0
                : 0.0;

        String phoneNumber = (requestor != null && requestor.getProfile() != null)
                ? requestor.getProfile().getPhoneNumber()
                : null;

        return HrOvertimeResponse.builder()
                .overtimeRecordId(entity.getOvertimeRecordId())
                .approvedDate(entity.getApprovedDate())
                .approvedStartTime(entity.getApprovedStartTime())
                .approvedEndTime(entity.getApprovedEndTime())
                .clockInTime(entity.getClockInTime())
                .clockOutTime(entity.getClockOutTime())
                .isHoliday(entity.isHoliday())
                .isWeekend(entity.isWeekend())
                .isNightTime(entity.isNightTime())
                .status(entity.getStatus())
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
                .requestorEmail(requestor != null ? requestor.getEmail() : null)
                .requestorPhoneNumber(phoneNumber)
                .totalApprovedHours(approvedHours)
                .totalActualHours(actualHours)
                .build();
    }

            // ─── XUẤT EXCEL OVERTIME ─────────────────────────────────────────
@Transactional(readOnly = true)
public byte[] exportOvertimeToExcel(UserRole userRole, OvertimeFilterRequest filter) {
    String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
    if (!myDepartment.equals("Human Resources") && !myDepartment.equals("Executive Leadership")
            && !permissionService.hasPermission(userRole.getUserId(), PermissionKey.OVERTIME_VIEW_ALL)) {
        throw new OvertimeException(OvertimeErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự hoặc Ban Giám Đốc mới có quyền xuất báo cáo làm thêm giờ");
    }

    // 1. Lấy toàn bộ dữ liệu khớp bộ lọc (không phân trang)
    Specification<OvertimeRecord> spec = OvertimeSpecification.forCompanyWide(filter);
    List<OvertimeRecord> records = overtimeRecordRepository.findAll(spec, Sort.by(Sort.Direction.DESC, "approvedDate"));
    List<HrOvertimeResponse> dtoList = records.stream().map(this::mapToHrResponse).toList();

    // 2. Tạo workbook Excel bằng Apache POI
    try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
        Sheet sheet = workbook.createSheet("Overtime Records");

        // Header Style (In đậm + Màu nền xám nhạt)
        CellStyle headerStyle = workbook.createCellStyle();
        Font headerFont = workbook.createFont();
        headerFont.setBold(true);
        headerStyle.setFont(headerFont);
        headerStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        headerStyle.setAlignment(HorizontalAlignment.CENTER);

        // Danh sách tiêu đề cột
        String[] columns = {
                "STT", "Mã NV", "Họ và Tên", "Phòng Ban", "Chức Vụ",
                "Ngày OT", "Giờ Bắt Đầu", "Giờ Kết Thúc",
                "Tổng Giờ Duyệt", "Tổng Giờ Thực Tế",
                "Cuối Tuần", "Ca Đêm", "Ngày Lễ", "Trạng Thái"
        };

        // Ghi dòng Header
        Row headerRow = sheet.createRow(0);
        for (int i = 0; i < columns.length; i++) {
            Cell cell = headerRow.createCell(i);
            cell.setCellValue(columns[i]);
            cell.setCellStyle(headerStyle);
        }

        // Ghi dữ liệu từng dòng
        DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm");
        int rowIdx = 1;

        for (HrOvertimeResponse rowData : dtoList) {
            Row row = sheet.createRow(rowIdx);

            row.createCell(0).setCellValue(rowIdx);
            row.createCell(1).setCellValue(rowData.getRequestorCode() != null ? rowData.getRequestorCode() : "");
            row.createCell(2).setCellValue(rowData.getRequestorName() != null ? rowData.getRequestorName() : "");
            row.createCell(3)
                    .setCellValue(rowData.getRequestorDepartment() != null ? rowData.getRequestorDepartment() : "");
            row.createCell(4).setCellValue(rowData.getRequestorJob() != null ? rowData.getRequestorJob() : "");
            row.createCell(5)
                    .setCellValue(rowData.getApprovedDate() != null ? rowData.getApprovedDate().toString() : "");
            row.createCell(6).setCellValue(
                    rowData.getApprovedStartTime() != null ? rowData.getApprovedStartTime().format(timeFormatter) : "");
            row.createCell(7).setCellValue(
                    rowData.getApprovedEndTime() != null ? rowData.getApprovedEndTime().format(timeFormatter) : "");
            row.createCell(8)
                    .setCellValue(rowData.getTotalApprovedHours() != null ? rowData.getTotalApprovedHours() : 0.0);
            row.createCell(9).setCellValue(rowData.getTotalActualHours() != null ? rowData.getTotalActualHours() : 0.0);
            row.createCell(10).setCellValue(Boolean.TRUE.equals(rowData.getIsWeekend()) ? "Có" : "Không");
            row.createCell(11).setCellValue(Boolean.TRUE.equals(rowData.getIsNightTime()) ? "Có" : "Không");
            row.createCell(12).setCellValue(Boolean.TRUE.equals(rowData.getIsHoliday()) ? "Có" : "Không");
            row.createCell(13).setCellValue(rowData.getStatus() != null ? rowData.getStatus().name() : "");
            rowIdx++;
        }

        // Auto resize độ rộng cột vừa vặn với nội dung
        for (int i = 0; i < columns.length; i++) {
            sheet.autoSizeColumn(i);
        }

        workbook.write(out);
        return out.toByteArray();
    } catch (IOException e) {
        log.error("Failed to generate Excel file", e);
        throw new OvertimeException(OvertimeErrorCode.INTERNAL_SERVER_ERROR,
                "Có lỗi xảy ra khi đang tạo và xuất báo cáo Excel");
    }
}

}