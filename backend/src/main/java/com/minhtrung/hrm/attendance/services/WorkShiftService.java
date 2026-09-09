package com.minhtrung.hrm.attendance.services;

import java.time.Duration;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.attendance.dtos.requests.CreateWorkShiftRequest;
import com.minhtrung.hrm.attendance.dtos.response.WorkShiftResponse;
import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.attendance.entities.WorkShiftSchedule;
import com.minhtrung.hrm.attendance.enums.AttendanceErrorCode;
import com.minhtrung.hrm.attendance.exceptions.AttendanceException;
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftScheduleRepository;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class WorkShiftService {

    private final WorkShiftRepository workShiftRepository;
    private final WorkShiftScheduleRepository workShiftScheduleRepository;

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
     * Tạo ca làm việc mới kèm lịch trình 7 ngày trong tuần (T2 - CN).
     * Chỉ Trưởng phòng HR hoặc Ban Giám Đốc mới có quyền tạo.
     * Kiểm tra chặt chẽ: <= 8 giờ/ngày và <= 48 giờ/tuần theo Bộ luật Lao động Việt Nam.
     */
    @Transactional
    public WorkShiftResponse createWorkShift(CreateWorkShiftRequest request, TokenPayload currentUser) {
        checkCreateShiftPermission(currentUser);

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
                startTime = dayReq.getStartTime();
                endTime = dayReq.getEndTime();
                restStart = dayReq.getRestStartTime();
                restEnd = dayReq.getRestEndTime();

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

        // 5. Lưu WorkShift và các WorkShiftSchedule
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
                currentUser.getUserId(), savedShift.getName(), activeWorkingDays, totalWeeklyHours);

        return mapToWorkShiftResponse(savedShift);
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

    private void checkCreateShiftPermission(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }

        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());
        boolean isHRHead = "Human Resources".equalsIgnoreCase(currentUser.getDepartment())
                && currentUser.getJob() != null
                && currentUser.getJob().contains("Head");

        if (!isExecutive && !isHRHead) {
            throw new AttendanceException(
                    AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                    "Chỉ có Trưởng phòng Nhân sự (HR Head) hoặc Ban Giám Đốc mới có quyền tạo ca làm việc mới!"
            );
        }
    }
}

