package com.minhtrung.hrm.employees.dtos.responses;

import java.util.List;
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
public class DepartmentResponse {
    private UUID departmentId;
    private String name;
    private int totalEmployees;
    private List<JobItemDto> jobs;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class JobItemDto {
        private UUID jobId;
        private String title;
    }
}
