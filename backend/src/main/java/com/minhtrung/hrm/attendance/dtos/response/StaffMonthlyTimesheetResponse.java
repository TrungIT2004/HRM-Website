package com.minhtrung.hrm.attendance.dtos.response;

import java.util.List;
import java.util.UUID;

import com.minhtrung.hrm.attendance.enums.TimesheetStatus;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StaffMonthlyTimesheetResponse {
    private UUID timesheetId;
    private int month;
    private int year;
    private TimesheetStatus status;
    private String note;

    private AttendanceSummaryDto attendance;
    private LeaveSummaryDto leave;
    private OvertimeSummaryDto overtime;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AttendanceSummaryDto {
        private int standardWorkingDays;    // Ngày công chuẩn theo ca riêng của User
        private double actualWorkedDays;     // Ngày đi làm thực tế (hỗ trợ số thực nửa ngày 0.5)
        private double actualWorkHours;      // Tổng số giờ làm việc thực tế
        private int lateCount;               // Số lần đi muộn
        private int totalLateMinutes;        // Tổng số phút đi muộn
        private int earlyDepartureCount;     // Số lần về sớm
        private double absentDays;           // Số ngày vắng không phép
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LeaveSummaryDto {
        private double paidLeaveDays;           // Số ngày nghỉ có lương trong tháng (trừ phép năm)
        private double unpaidLeaveDays;         // Số ngày nghỉ không lương trong tháng
        private double remainingAnnualLeaveDays;// Phép năm còn lại
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OvertimeSummaryDto {
        private double totalActualHours;     // Tổng giờ OT thực tế
        private double totalPaidHours;       // Tổng giờ OT quy đổi tính tiền lương
        private List<OvertimeDetailDto> details;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OvertimeDetailDto {
        private String type;                 // NORMAL_DAY, NORMAL_NIGHT, WEEKEND_DAY, WEEKEND_NIGHT, HOLIDAY_DAY, HOLIDAY_NIGHT
        private String label;                // Nhãn hiển thị: Ngày thường (150%), Đêm ngày thường (210%)...
        private double hours;                // Số giờ thực tế
        private double multiplier;           // Hệ số (1.5, 2.1, 2.0, 2.7, 3.0, 3.9)
        private double paidHours;            // Giờ tính tiền = hours * multiplier
    }
}
