package com.minhtrung.hrm.employees.dtos.responses;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO chứa thông tin hồ sơ công khai của nhân viên (Trang chính & Danh bạ công ty).
 * Dữ liệu được tổng hợp từ 6 bảng:
 * - users: Thông tin định danh cơ bản, email công ty, ngày vào làm, ngày sinh.
 * - jobs: Chức danh/vị trí công việc.
 * - departments: Tên phòng ban.
 * - user_profiles: Số điện thoại liên hệ công việc.
 * - attendances: Trạng thái có mặt/nghỉ làm trong ngày hôm nay.
 * - work_shifts & work_shift_schedules: Ca làm việc và thời khóa biểu 7 ngày trong tuần.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeePublicProfile {

    // 1. Nhận diện nhân sự (Từ bảng users)
    private UUID userId;
    private String employeeCode;
    private String firstName;
    private String lastName;
    private String fullName;
    private String profilePicUrl;
    private String gender;

    // Ngày sinh (dùng hiển thị sinh nhật công khai dạng dd/MM) & Ngày vào làm
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate joinedDate;

    // 2. Vị trí & Phòng ban (Từ bảng jobs & departments)
    private String jobTitle;
    private String departmentName;

    // 3. Kênh liên lạc công việc (users.email & user_profiles.phone_number)
    private String workEmail;
    private String phoneNumber;

    // 4. Trạng thái làm việc hôm nay (Từ bảng attendances / overtime_records)
    // todayStatus: truyền thẳng attendances.status; "DAY_OFF" = không có bản ghi (nghỉ).
    private String todayStatus;
    // "OVERTIMING" = đang tăng ca, "OVERTIME_DONE" = đã kết thúc tăng ca, null = không tăng ca.
    private String todayOvertimeStatus;

    // 5. Ca làm việc & Lịch làm việc tuần (Từ bảng work_shifts & work_shift_schedules)
    private String shiftName;
    private List<WorkShiftScheduleDto> weeklySchedule;

    // 6. Trạng thái tài khoản (Đang làm việc hay Đã thôi việc)
    private boolean isActive;

    /**
     * DTO con biểu diễn lịch làm việc từng ngày trong tuần (Thứ 2 -> Chủ Nhật)
     */
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WorkShiftScheduleDto {
        private int dayOfWeek;       // 2 = Thứ Hai, ..., 7 = Thứ Bảy, 8 = Chủ Nhật
        private String dayName;      // "Thứ 2", "Thứ 3", ..., "Chủ Nhật"
        
        @JsonProperty("isWorking")
        private boolean isWorking;   // true: Có làm việc, false: Nghỉ (OFF)

        @JsonFormat(pattern = "HH:mm")
        private LocalTime startTime;

        @JsonFormat(pattern = "HH:mm")
        private LocalTime endTime;

        @JsonFormat(pattern = "HH:mm")
        private LocalTime restStartTime;

        @JsonFormat(pattern = "HH:mm")
        private LocalTime restEndTime;
    }
}
