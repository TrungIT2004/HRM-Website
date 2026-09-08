package com.minhtrung.social_app.leave.dtos.responses;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import com.minhtrung.social_app.leave.enums.LeaveRequestStatus;
import lombok.*;
import lombok.experimental.SuperBuilder;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class StaffLeaveResponse {
    private UUID requestId;
    private LocalDate fromDate;
    private LocalDate toDate;
    private String reason;
    private String rejectionReason;
    private int paidLeaveDays;
    private LeaveRequestStatus status;
    private LocalDateTime createdAt;
    
    private UUID approverId;
    private String approverName;
    private String approverJob;
}