package com.minhtrung.hrm.leave.dtos.responses;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeavePreviewResponse {
    private long requestedLeaveDays;
    private int workDays;
    private int restDays;
    private int holidayDays;
    private int annualLeaveDays;
    private int usedLeaveDays;
    private int remainingAnnualLeaveDays;
    private int remainingAfterThisRequest;
    private boolean isSufficientAnnualLeave;
}
