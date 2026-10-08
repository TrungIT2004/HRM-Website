package com.minhtrung.hrm.dashboard.dtos.responses;

import java.time.LocalDate;
import java.time.LocalTime;

import com.fasterxml.jackson.annotation.JsonFormat;

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
public class DashboardSummaryResponse {

    private UserProfileDto userProfile;
    private TodayAttendanceDto todayAttendance;
    private MonthlySummaryDto monthlySummary;
    private LeaveBalanceDto leaveBalance;
    private PendingApprovalsDto pendingApprovals;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UserProfileDto {
        private String fullName;
        private String employeeCode;
        private String department;
        private String job;
        private String profilePicUrl;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TodayAttendanceDto {
        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate workDate;
        private boolean hasClockIn;
        @JsonFormat(pattern = "HH:mm:ss")
        private LocalTime clockInTime;
        @JsonFormat(pattern = "HH:mm:ss")
        private LocalTime clockOutTime;
        private String status;
        private Double workingHours;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MonthlySummaryDto {
        private int month;
        private int year;
        private double actualWorkDays;
        private int standardWorkDays;
        private double totalWorkHours;
        private int lateDays;
        private double totalOtHours;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LeaveBalanceDto {
        private int totalAnnualLeave;
        private int usedLeaveDays;
        private double remainingLeaveDays;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PendingApprovalsDto {
        private boolean isApprover;
        private long pendingLeavesCount;
        private long pendingOvertimesCount;
    }
}
