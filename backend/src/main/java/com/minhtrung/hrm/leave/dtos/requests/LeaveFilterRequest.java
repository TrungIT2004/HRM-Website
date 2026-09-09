package com.minhtrung.hrm.leave.dtos.requests;

import java.time.LocalDate;

import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class LeaveFilterRequest {
    private Boolean isMine;
    private LeaveRequestStatus status;
    private LocalDate fromDate;
    private LocalDate toDate;
    private String keyword;
}
