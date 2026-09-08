package com.minhtrung.social_app.leave.dtos.responses;

import java.util.UUID;
import lombok.*;
import lombok.experimental.SuperBuilder;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder 
public class ManagerLeaveResponse extends StaffLeaveResponse {
    private UUID requestorId;
    private String requestorCode;
    private String requestorName;
    private String requestorDepartment;
    private String requestorJob;
    private String requestorProfilePicUrl;
}