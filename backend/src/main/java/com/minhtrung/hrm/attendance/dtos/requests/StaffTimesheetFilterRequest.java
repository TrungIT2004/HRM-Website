package com.minhtrung.hrm.attendance.dtos.requests;

import com.minhtrung.hrm.attendance.enums.TimesheetStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StaffTimesheetFilterRequest {
    private Integer month;
    private Integer year;
    private TimesheetStatus status;
}
