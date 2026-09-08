package com.minhtrung.social_app.attendance.dtos.response;

import java.time.LocalDate;
import java.time.LocalTime;

import com.minhtrung.social_app.attendance.enums.AttendanceStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class StaffAttendanceResponse {
    private LocalDate workDate;
    private LocalTime clockInTime;
    private LocalTime clockOutTime;
    private AttendanceStatus status;
    private boolean isEdited;
    private String editedReason;
}
