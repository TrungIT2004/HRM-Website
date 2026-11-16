package com.minhtrung.hrm.attendance.dtos.response;

import java.util.List;
import java.util.UUID;

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
public class AttendanceOverviewResponse {
    private java.time.LocalDate periodStart;
    private java.time.LocalDate periodEnd;
    private long lateEarlyCount;
    private long actualLeaveCount;
    private long plannedLeaveCount;
    private List<DeptLeaveDto> leaveByDept;
    private List<WeeklyPointDto> weeklyTrend;
    private List<LeaveTypeDto> leaveTypes;
    private List<TopAbsenteeDto> topAbsentees;
    private long totalLeaveDays;
    private double otTotalHours;
    private List<OtDeptDto> otByDept;
    private List<TopOtDto> topOt;
    private List<DeptLeaveDto> lateByDept;
    private List<WeeklyPointDto> lateTrend;
    private long otSubmitted;
    private long otApproved;
    private long otRejected;
    private List<WeeklyPointDto> otTrend;
    private long leaveApproved;
    private long leaveRejected;
    private double totalWorkDays;
    private long lateCount;
    private long earlyCount;
    private long onTimeCount;
    private java.util.Map<String, Long> statusCounts;
    private java.util.List<TopAbsenteeDto> missingTop;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DeptLeaveDto {
        private String department;
        private long days;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WeeklyPointDto {
        private String label;
        private long days;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LeaveTypeDto {
        private String label;
        private long count;
        private double percent;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TopAbsenteeDto {
        private UUID userId;
        private String fullName;
        private String department;
        private double days;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OtDeptDto {
        private String department;
        private double hours;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TopOtDto {
        private UUID userId;
        private String fullName;
        private String department;
        private double hours;
    }
}
