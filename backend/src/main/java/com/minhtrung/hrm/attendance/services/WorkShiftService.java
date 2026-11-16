package com.minhtrung.hrm.attendance.services;

import java.time.Duration;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.minhtrung.hrm.attendance.dtos.requests.CreateWorkShiftRequest;
import com.minhtrung.hrm.attendance.dtos.response.WorkShiftResponse;
import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.attendance.entities.WorkShiftSchedule;
import com.minhtrung.hrm.attendance.enums.AttendanceErrorCode;
import com.minhtrung.hrm.attendance.exceptions.AttendanceException;
import com.minhtrung.hrm.attendance.repositories.AttendanceRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftScheduleRepository;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class WorkShiftService {

    private final WorkShiftRepository workShiftRepository;
    private final WorkShiftScheduleRepository workShiftScheduleRepository;
    private final PermissionService permissionService;
    private final AttendanceRepository attendanceRepository;
    private final UserRepository userRepository;

    /**
     * Lấy danh sách toàn bộ các ca làm việc đang hoạt động cùng lịch 7 ngày trong tuần.
     */
    @Transactional(readOnly = true)
    public List<WorkShiftResponse> getAllWorkShifts() {
        List<WorkShift> shifts = workShiftRepository.findAll();
        return shifts.stream()
                .map(this::mapToWorkShiftResponse)
                .toList();
    }

    /**
     * Ca làm việc của chính nhân viên đang đăng nhập (dùng cho trang /attendance/schedule).
     */
    @Transactional(readOnly = true)
    public WorkShiftResponse getMyWorkShift(UUID userId) {
        WorkShift shift = userRepository.getUsersWorkShift(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Tài khoản chưa được phân ca làm việc. Vui lòng liên hệ phòng Nhân sự."));
        return mapToWorkShiftResponse(shift);
    }

    /**
     * Tạo ca làm việc mới kèm lịch trình 7 ngày trong tuần (T2 - CN).
     * Kiểm tra chặt chẽ: <= 8 giờ/ngày và <= 48 giờ/tuần theo Bộ luật Lao động Việt Nam.
     */
    @Transactional
    public WorkShiftResponse createWorkShift(CreateWorkShiftRequest request, TokenPayload currentUser) {
        checkCreateShiftPermission(currentUser);

        List<WorkShiftSchedule> schedulesToSave = buildValidatedSchedules(request);

        WorkShift shift = WorkShift.builder()
                .name(request.getName().trim())
                .build();
        WorkShift savedShift = workShiftRepository.save(shift);

        for (WorkShiftSchedule schedule : schedulesToSave) {
            schedule.setWorkShift(savedShift);
        }
        List<WorkShiftSchedule> savedSchedules = workShiftScheduleRepository.saveAll(schedulesToSave);
        savedShift.setSchedules(savedSchedules);

        log.info("Người dùng {} đã tạo ca làm việc mới thành công: {} ({} ngày làm việc/tuần, tổng {:.1f} giờ/tuần)",
                currentUser.getUserId(), savedShift.getName(),
                countWorkingDays(schedulesToSave), sumWeeklyHours(schedulesToSave));

        return mapToWorkShiftResponse(savedShift);
    }

    @Transactional
    public WorkShiftResponse updateWorkShift(UUID shiftId, CreateWorkShiftRequest request, TokenPayload currentUser) {
        checkCreateShiftPermission(currentUser);

        WorkShift shift = workShiftRepository.findById(shiftId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy ca làm việc với ID: " + shiftId));

        List<WorkShiftSchedule> schedulesToSave = buildValidatedSchedules(request);

        // work_shift_schedules có UNIQUE (shift_id, day_of_week) và WorkShift.schedules có
        // orphanRemoval = true. Xoá rồi insert sẽ đụng cả hai (unique violation hoặc
        // "collection with orphan deletion was no longer referenced"). buildValidatedSchedules
        // luôn trả đúng 7 ngày nên chỉ cần cập nhật tại chỗ — không xoá/insert gì cả.
        Map<Integer, WorkShiftSchedule> existing = shift.getSchedules().stream()
                .collect(Collectors.toMap(WorkShiftSchedule::getDayOfWeek, s -> s, (a, b) -> a));
        for (WorkShiftSchedule incoming : schedulesToSave) {
            WorkShiftSchedule current = existing.remove(incoming.getDayOfWeek());
            if (current != null) {
                current.setWorking(incoming.isWorking());
                current.setStartTime(incoming.getStartTime());
                current.setEndTime(incoming.getEndTime());
                current.setRestStartTime(incoming.getRestStartTime());
                current.setRestEndTime(incoming.getRestEndTime());
            } else {
                incoming.setWorkShift(shift);
                workShiftScheduleRepository.save(incoming);
            }
        }
        // ngày nào không còn trong lịch mới thì xoá (orphanRemoval lo phần còn lại khi xoá cả ca)
        existing.values().forEach(workShiftScheduleRepository::delete);

        shift.setName(request.getName().trim());
        workShiftRepository.save(shift);
        workShiftScheduleRepository.flush();

        log.info("Người dùng {} đã cập nhật ca làm việc {}: {} ({} ngày làm việc/tuần, tổng {:.1f} giờ/tuần)",
                currentUser.getUserId(), shiftId, shift.getName(),
                countWorkingDays(schedulesToSave), sumWeeklyHours(schedulesToSave));

        return mapToWorkShiftResponse(shift);
    }

    /**
     * Xoá ca làm việc — chặn nếu còn nhân viên dùng hoặc đã có lịch sử chấm công.
     * attendances tham chiếu work_shifts nên xoá ca sẽ mất dữ liệu chấm công.
     */
    @Transactional
    public void deleteWorkShift(UUID shiftId, TokenPayload currentUser) {
        checkCreateShiftPermission(currentUser);

        WorkShift shift = workShiftRepository.findById(shiftId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy ca làm việc với ID: " + shiftId));

        long attendanceCount = attendanceRepository.countByShift_ShiftId(shiftId);
        if (attendanceCount > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Không thể xoá ca '" + shift.getName() + "': đang có " + attendanceCount
                            + " bản ghi chấm công tham chiếu tới ca này. Xoá sẽ mất lịch sử chấm công.");
        }
        int employeeCount = userRepository.countByShift_ShiftId(shiftId);
        if (employeeCount > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Không thể xoá ca '" + shift.getName() + "': còn " + employeeCount
                            + " nhân viên đang được xếp vào ca này. Hãy chuyển họ sang ca khác trước.");
        }

        // orphanRemoval = true sẽ tự xoá các schedule con; clear() để Hibernate theo dõi
        shift.getSchedules().clear();
        workShiftScheduleRepository.flush();
        workShiftRepository.delete(shift);

        log.info("Người dùng {} đã xoá ca làm việc {}", currentUser.getUserId(), shiftId);
    }

    private long countWorkingDays(List<WorkShiftSchedule> schedules) {
        return schedules.stream().filter(WorkShiftSchedule::isWorking).count();
    }

    private double sumWeeklyHours(List<WorkShiftSchedule> schedules) {
        return schedules.stream()
                .filter(WorkShiftSchedule::isWorking)
                .mapToDouble(s -> {
                    double total = Duration.between(s.getStartTime(), s.getEndTime()).toMinutes() / 60.0;
                    double rest = (s.getRestStartTime() != null && s.getRestEndTime() != null)
                            ? Duration.between(s.getRestStartTime(), s.getRestEndTime()).toMinutes() / 60.0
                            : 0.0;
                    return total - rest;
                }).sum();
    }

    /**
     * Dựng + kiểm tra lịch 7 ngày. Dùng chung cho create và update nên không lặp logic luật lao động.
     */
    private List<WorkShiftSchedule> buildValidatedSchedules(CreateWorkShiftRequest request) {
        // 1. Phân loại lịch trình theo dayOfWeek (1..7)
        Map<Integer, CreateWorkShiftRequest.DailyScheduleRequest> scheduleMap = request.getSchedules().stream()
                .collect(Collectors.toMap(
                        CreateWorkShiftRequest.DailyScheduleRequest::getDayOfWeek,
                        s -> s,
                        (existing, replacement) -> replacement
                ));

        double totalWeeklyHours = 0.0;
        int activeWorkingDays = 0;
        List<WorkShiftSchedule> schedulesToSave = new ArrayList<>();

        // 2. Validate từng ngày từ Thứ 2 (1) đến Chủ nhật (7)
        for (int day = 1; day <= 7; day++) {
            CreateWorkShiftRequest.DailyScheduleRequest dayReq = scheduleMap.get(day);
            String dayName = mapDayOfWeekToVietnameseName(day);

            boolean isWorking = (dayReq != null && dayReq.isWorking());
            LocalTime startTime = LocalTime.of(0, 0);
            LocalTime endTime = LocalTime.of(0, 0);
            LocalTime restStart = null;
            LocalTime restEnd = null;

            if (isWorking) {
                startTime = parseTime(dayReq.getStartTime(), dayName, "giờ bắt đầu làm việc");
                endTime = parseTime(dayReq.getEndTime(), dayName, "giờ kết thúc làm việc");
                restStart = parseTime(dayReq.getRestStartTime(), dayName, "giờ bắt đầu nghỉ");
                restEnd = parseTime(dayReq.getRestEndTime(), dayName, "giờ kết thúc nghỉ");

                // Giờ bắt đầu và kết thúc làm việc bắt buộc có
                if (startTime == null || endTime == null) {
                    throw new AttendanceException(
                            AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                            "Ngày " + dayName + " là ngày làm việc nên bắt buộc phải có startTime và endTime!"
                    );
                }

                // Thứ tự giờ làm việc
                if (!startTime.isBefore(endTime)) {
                    throw new AttendanceException(
                            AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                            "Ngày " + dayName + ": Giờ bắt đầu làm việc (" + startTime + ") phải diễn ra trước giờ kết thúc (" + endTime + ")!"
                    );
                }

                // Khung giờ nghỉ ngơi (nếu có)
                double restHours = 0.0;
                if (restStart != null || restEnd != null) {
                    if (restStart == null || restEnd == null) {
                        throw new AttendanceException(
                                AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                                "Ngày " + dayName + ": Cần cung cấp đầy đủ cả giờ bắt đầu và giờ kết thúc nghỉ ngơi!"
                        );
                    }
                    if (!restStart.isBefore(restEnd)) {
                        throw new AttendanceException(
                                AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                                "Ngày " + dayName + ": Giờ bắt đầu nghỉ (" + restStart + ") phải trước giờ kết thúc nghỉ (" + restEnd + ")!"
                        );
                    }
                    if (restStart.isBefore(startTime) || restEnd.isAfter(endTime)) {
                        throw new AttendanceException(
                                AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                                "Ngày " + dayName + ": Khung giờ nghỉ ngơi phải nằm trọn vẹn trong khung giờ làm việc!"
                        );
                    }
                    restHours = Duration.between(restStart, restEnd).toMinutes() / 60.0;
                }

                // Thời gian làm việc trong ngày (không quá 8 tiếng)
                double dailyDurationHours = Duration.between(startTime, endTime).toMinutes() / 60.0;
                double dailyWorkHours = dailyDurationHours - restHours;

                if (dailyWorkHours > 8.0) {
                    throw new AttendanceException(
                            AttendanceErrorCode.WORK_SHIFT_DAILY_HOURS_EXCEEDED,
                            String.format("Thời gian làm việc thực tế ngày %s không được vượt quá 8 giờ! (Hiện tại: %.1f giờ)", dayName, dailyWorkHours)
                    );
                }

                totalWeeklyHours += dailyWorkHours;
                activeWorkingDays++;
            }

            WorkShiftSchedule schedule = WorkShiftSchedule.builder()
                    .dayOfWeek(day)
                    .isWorking(isWorking)
                    .startTime(startTime)
                    .endTime(endTime)
                    .restStartTime(restStart)
                    .restEndTime(restEnd)
                    .build();

            schedulesToSave.add(schedule);
        }

        // 3. Kiểm tra số ngày làm việc tối thiểu
        if (activeWorkingDays == 0) {
            throw new AttendanceException(
                    AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                    "Ca làm việc phải có ít nhất 1 ngày làm việc trong tuần!"
            );
        }

        // 4. Kiểm tra tổng giờ làm việc trong tuần (không quá 48 tiếng)
        if (totalWeeklyHours > 48.0) {
            throw new AttendanceException(
                    AttendanceErrorCode.WORK_SHIFT_WEEKLY_HOURS_EXCEEDED,
                    String.format("Tổng thời gian làm việc trong một tuần không được vượt quá 48 giờ theo Luật Lao động! (Hiện tại: %.1f giờ/tuần với %d ngày làm việc)", totalWeeklyHours, activeWorkingDays)
            );
        }

        return schedulesToSave;
    }

    /**
     * Parse giờ từ browser (<input type=time> gửi "HH:mm", dữ liệu cũ "HH:mm:ss").
     * Chuỗi rỗng/thiếu = null (ngày không nghỉ trưa). Sai format -> 400 kèm msg rõ ràng
     * thay vì để Jackson nổ HttpMessageNotReadable rồi rơi vào 500 generic.
     */
    private LocalTime parseTime(String raw, String dayName, String fieldLabel) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String t = raw.trim();
        try {
            return t.length() == 5
                    ? LocalTime.parse(t, DateTimeFormatter.ofPattern("HH:mm"))
                    : LocalTime.parse(t, DateTimeFormatter.ofPattern("HH:mm:ss"));
        } catch (DateTimeParseException e) {
            throw new AttendanceException(
                    AttendanceErrorCode.WORK_SHIFT_INVALID_TIME,
                    "Ngày " + dayName + ": " + fieldLabel + " ('" + t + "') sai định dạng, dùng HH:mm (ví dụ 08:00)!"
            );
        }
    }

    private WorkShiftResponse mapToWorkShiftResponse(WorkShift shift) {
        List<WorkShiftSchedule> schedules = workShiftScheduleRepository.findByWorkShift_ShiftId(shift.getShiftId());
        List<WorkShiftResponse.WorkShiftScheduleItemDto> scheduleDtos = schedules.stream()
                .sorted(Comparator.comparing(WorkShiftSchedule::getDayOfWeek))
                .map(s -> WorkShiftResponse.WorkShiftScheduleItemDto.builder()
                        .scheduleId(s.getScheduleId())
                        .dayOfWeek(s.getDayOfWeek())
                        .dayName(mapDayOfWeekToVietnameseName(s.getDayOfWeek()))
                        .isWorking(s.isWorking())
                        .startTime(s.getStartTime())
                        .endTime(s.getEndTime())
                        .restStartTime(s.getRestStartTime())
                        .restEndTime(s.getRestEndTime())
                        .build())
                .toList();

        return WorkShiftResponse.builder()
                .shiftId(shift.getShiftId())
                .name(shift.getName())
                .schedules(scheduleDtos)
                .build();
    }

    private String mapDayOfWeekToVietnameseName(int dayOfWeek) {
        return switch (dayOfWeek) {
            case 1 -> "Thứ 2";
            case 2 -> "Thứ 3";
            case 3 -> "Thứ 4";
            case 4 -> "Thứ 5";
            case 5 -> "Thứ 6";
            case 6 -> "Thứ 7";
            case 7 -> "Chủ nhật";
            default -> "Không xác định";
        };
    }

    /**
     * Quyền quản lý ca làm việc — dùng chung ORG_MANAGE với phòng ban / chức danh.
     * Quyền gốc: phòng Human Resources. Ban Giám Đốc đã bị gỡ.
     */
    private void checkCreateShiftPermission(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }

        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        boolean hasGrant = permissionService.hasPermission(currentUser.getUserId(), PermissionKey.ORG_MANAGE);

        if (!isHR && !hasGrant) {
            throw new AttendanceException(
                    AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                    "Chỉ có phòng Nhân sự (Human Resources) mới có quyền quản lý ca làm việc!"
            );
        }
    }
}

