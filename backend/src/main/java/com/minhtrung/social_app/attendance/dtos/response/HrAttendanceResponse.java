package com.minhtrung.social_app.attendance.dtos.response;

import java.time.LocalTime;
import java.time.LocalDate;
import java.util.UUID;

import com.minhtrung.social_app.attendance.enums.AttendanceStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class HrAttendanceResponse {
    private UUID attendanceId;
    private UUID userId;
    private String employeeCode;
    private String fullName;
    private String department;
    private String job;
    private LocalDate workDate;
    private LocalTime clockInTime, clockOutTime;
    private AttendanceStatus status;
    private boolean isEdited;
    private String editedReason;
    private String editorName;
    private String editorEmpCode;
}
