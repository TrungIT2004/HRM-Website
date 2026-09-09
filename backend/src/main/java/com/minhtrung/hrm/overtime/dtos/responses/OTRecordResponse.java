package com.minhtrung.hrm.overtime.dtos.responses;

import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
@Getter
public class OTRecordResponse {
    private UUID overtimeRecordId;

    private UUID requestorId;
    private String requestorFullname;
    private String requestorDepartment;
    private String requestorJob;
    
    private UUID approverId;
    private String approverFullname;
    private String approverDepartment;
    private String approverJob;

    private LocalDateTime approvedStartTime;
    private LocalDateTime approvedEndTime;
    private LocalDateTime clockInTime;
    private LocalDateTime clockOutTime;

    private boolean isNightTime;
    private boolean isWeekend;
    private boolean isHoliday;

    private String reason;
    private String rejectionReason;

    private OvertimeRecordStatus status;
}
