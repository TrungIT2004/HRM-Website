package com.minhtrung.social_app.leave.dtos.requests;

import java.time.LocalDate;

import com.minhtrung.social_app.leave.enums.LeaveRequestStatus;

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
