package com.minhtrung.hrm.performance.dtos.requests;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PerformanceFilterRequest {
    private String periodType; // MONTHLY | YEARLY
    private Integer year;
    private Integer month;
    private String status;
    private String keyword; // ho ten / ma NV
    private String department;
}
