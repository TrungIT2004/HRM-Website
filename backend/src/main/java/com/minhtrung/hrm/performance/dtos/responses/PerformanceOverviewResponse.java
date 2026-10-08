package com.minhtrung.hrm.performance.dtos.responses;

import java.util.List;
import java.util.Map;

import com.minhtrung.hrm.performance.dtos.responses.PerformanceReviewResponse;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PerformanceOverviewResponse {
    private long total;
    private Double avgScore;
    private Map<String, Long> byStatus;
    private List<DeptAvg> avgByDept;
    // ponytail: tai su dung response day du thay DTO rieng — dashboard can ten + diem + phong
    private List<PerformanceReviewResponse> excellent;
    private List<PerformanceReviewResponse> belowTarget;

    @Getter
    @Builder
    public static class DeptAvg {
        private String department;
        private Double avg;
        private long count;
    }
}
