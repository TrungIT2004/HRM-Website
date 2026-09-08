package com.minhtrung.social_app.attendance.dtos.requests;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import com.minhtrung.social_app.attendance.enums.AttendanceStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class AttendanceFilterRequest {
    private Boolean isMine;
    private LocalDate startDate;
    private LocalDate endDate;
    private AttendanceStatus status;
    private String keyword;
    private List<String> departmentNames;
    
    private UUID forcedUserId; 
    private UUID forcedDepartmentId;
}
