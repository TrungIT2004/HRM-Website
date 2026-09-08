package com.minhtrung.social_app.overtime.dtos.responses;

import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.social_app.overtime.enums.OvertimeRecordStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
@Getter
public class OneselfOTRecordResponse {
    private UUID overtimeRecordId;
    
    private UUID approverId;
    private String approverFullname;

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
