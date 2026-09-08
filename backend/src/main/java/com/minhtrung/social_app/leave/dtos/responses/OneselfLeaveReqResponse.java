package com.minhtrung.social_app.leave.dtos.responses;

import java.time.LocalDate;
import java.util.UUID;

import com.minhtrung.social_app.leave.enums.LeaveRequestStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
@Getter
public class OneselfLeaveReqResponse {
    private UUID requestId;

    private UUID approverId;
    private String approverFullname;

    private LocalDate fromDate;
    private LocalDate toDate;
    private int paidLeaveDays;
    private String reason;
    private String rejectionReason;
    private LeaveRequestStatus status;
}
