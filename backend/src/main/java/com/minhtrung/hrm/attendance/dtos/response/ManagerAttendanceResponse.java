package com.minhtrung.hrm.attendance.dtos.response;

import java.time.LocalDate;
import java.time.LocalTime;

import com.minhtrung.hrm.attendance.enums.AttendanceStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class ManagerAttendanceResponse {
    private String employeeCode;
    private String fullName;
    private String department;
    private String job;
    private LocalDate workDate;
    private LocalTime clockInTime;
    private LocalTime clockOutTime;
    private AttendanceStatus status;
    private boolean isEdited;
    private String editedReason;
}
