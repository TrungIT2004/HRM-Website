package com.minhtrung.hrm.performance.dtos.responses;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import com.minhtrung.hrm.performance.enums.PeriodType;
import com.minhtrung.hrm.performance.enums.ReviewStatus;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PerformanceReviewResponse {
    private UUID reviewId;
    private UUID userId;
    private String employeeCode;
    private String revieweeName;
    private String department;
    private String job;
    private PeriodType periodType;
    private int periodMonth;
    private int periodYear;
    private ReviewStatus status;
    private Double avgSelf;
    private Double avgManager;
    private String overallSummary;
    private String nextGoals;
    private LocalDateTime selfAt;
    private LocalDateTime managerAt;
    private UUID evaluatorId;
    private String evaluatorName;
    private String departmentName;
    private UUID lockedBy;
    private LocalDateTime lockedAt;
    private boolean leaderConfirmed;
    private List<ScoreResponse> scores;

    @Getter
    @Builder
    public static class ScoreResponse {
        private UUID scoreId;
        private String criterionCode;
        private String criterionText;
        private int sortOrder;
        private Integer selfScore;
        private Integer managerScore;
        private String note;
    }
}
