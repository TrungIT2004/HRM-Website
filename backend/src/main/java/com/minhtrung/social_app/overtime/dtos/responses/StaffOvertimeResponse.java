package com.minhtrung.social_app.overtime.dtos.responses;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.social_app.overtime.enums.OvertimeRecordStatus;

import lombok.*;
import lombok.experimental.SuperBuilder;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class StaffOvertimeResponse {
    private UUID overtimeRecordId;
    private LocalDate approvedDate;
    private LocalDateTime approvedStartTime;
    private LocalDateTime approvedEndTime;
    private LocalDateTime clockInTime;
    private LocalDateTime clockOutTime;
    private Boolean isHoliday;
    private Boolean isWeekend;
    private Boolean isNightTime;
    private OvertimeRecordStatus status;
    private String reason;
    private String rejectionReason;

    private UUID approverId;
    private String approverName;
    private String approverJob;
}