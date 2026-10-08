package com.minhtrung.hrm.employees.dtos.responses;

import java.util.List;

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
public class OrganizationOverviewResponse {
    private long totalEmployees;
    private long totalDepartments;
    private long totalJobs;
    private List<DeptSliceDto> deptBreakdown;
    private List<ContractSliceDto> contractBreakdown;
    private List<Integer> monthlyHires;
    private List<Integer> monthlyLeavers;
    private List<Integer> headcountTrend;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DeptSliceDto {
        private String name;
        private long count;
        private double percent;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ContractSliceDto {
        private String type;
        private long count;
        private double percent;
    }
}
