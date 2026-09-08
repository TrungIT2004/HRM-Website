package com.minhtrung.social_app.attendance.dtos.requests;

import java.util.List;

import com.minhtrung.social_app.attendance.enums.TimesheetStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CompanyTimesheetFilterRequest {
    private Integer month;
    private Integer year;
    private TimesheetStatus status;
    private String keyword;
    private List<String> departmentNames;
}
