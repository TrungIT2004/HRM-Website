package com.minhtrung.social_app.leave.dtos.responses;

import lombok.*;
import lombok.experimental.SuperBuilder;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder 
public class HrLeaveResponse extends ManagerLeaveResponse {
    private Integer totalAnnualLeaveDays;
    private Integer usedLeaveDays;
    private Integer remainingAnnualLeaveDays;
    private String requestorEmail;
    private String requestorPhoneNumber;
}