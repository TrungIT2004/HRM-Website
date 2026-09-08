package com.minhtrung.social_app.attendance.dtos.response;

import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.social_app.attendance.dtos.response.StaffMonthlyTimesheetResponse.AttendanceSummaryDto;
import com.minhtrung.social_app.attendance.dtos.response.StaffMonthlyTimesheetResponse.LeaveSummaryDto;
import com.minhtrung.social_app.attendance.dtos.response.StaffMonthlyTimesheetResponse.OvertimeSummaryDto;
import com.minhtrung.social_app.attendance.enums.TimesheetStatus;

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
public class CompanyMonthlyTimesheetResponse {
    private UUID timesheetId;
    private UUID userId;
    private String employeeCode;
    private String fullName;
    private String department;
    private String job;

    private int month;
    private int year;
    private TimesheetStatus status;
    private String note;

    private AttendanceSummaryDto attendance;
    private LeaveSummaryDto leave;
    private OvertimeSummaryDto overtime;

    private LocalDateTime lockedAt;
    private UUID lockedBy;
}
