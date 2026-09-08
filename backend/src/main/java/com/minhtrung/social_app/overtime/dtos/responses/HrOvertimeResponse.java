package com.minhtrung.social_app.overtime.dtos.responses;

import lombok.*;
import lombok.experimental.SuperBuilder;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class HrOvertimeResponse extends ManagerOvertimeResponse {
    private String requestorEmail;
    private String requestorPhoneNumber;
    private Double totalApprovedHours;
    private Double totalActualHours;
}