package com.minhtrung.social_app.leave.dtos.responses;

import java.time.LocalDate;
import java.util.UUID;

import com.minhtrung.social_app.leave.enums.LeaveRequestStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class LeaveRequestResponse {
    private UUID requestId;

    private UUID requestorId;
    private String requestorFullname;
    private String requestorDepartment;
    private String requestorJob;

    private UUID approverId;
    private String approverFullname;
    private String approverDepartment;
    private String approverJob;

    private LocalDate fromDate;
    private LocalDate toDate;
    private int paidLeaveDays;
    private String reason;
    private String rejectionReason;
    private LeaveRequestStatus status;
}
