package com.minhtrung.social_app.employees.dtos.requests;

import java.util.UUID;

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
public class UpdateAssignmentRequest {
    private UUID departmentId;
    private UUID jobId;
    private UUID shiftId;
}
