package com.minhtrung.hrm.performance.entities;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.performance.enums.PeriodType;
import com.minhtrung.hrm.performance.enums.ReviewStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
@Entity
@Table(
    name = "performance_reviews",
    // ponytail: YEARLY dung month=0 thay vi NULL de UNIQUE van bat trung
    uniqueConstraints = @UniqueConstraint(name = "uk_review_user_period", columnNames = {"user_id", "period_type", "period_month", "period_year"})
)
public class PerformanceReview {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID reviewId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_review_user"))
    @JsonIgnore
    private User user;

    // Nguoi cham chinh (Người đánh giá) — set khi manager cham
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "evaluator_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_review_evaluator"))
    @JsonIgnore
    private User evaluator;

    @Enumerated(EnumType.STRING)
    @Column(name = "period_type", nullable = false, length = 10)
    private PeriodType periodType;

    @Column(name = "period_month", nullable = false)
    private int periodMonth;

    @Column(name = "period_year", nullable = false)
    private int periodYear;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ReviewStatus status = ReviewStatus.DRAFT;

    @Column(name = "avg_self")
    private Double avgSelf;

    @Column(name = "avg_manager")
    private Double avgManager;

    @Column(name = "overall_summary", columnDefinition = "TEXT")
    private String overallSummary;

    @Column(name = "next_goals", columnDefinition = "TEXT")
    private String nextGoals;

    @Column(name = "self_at")
    private LocalDateTime selfAt;

    @Column(name = "manager_at")
    private LocalDateTime managerAt;

    @Column(name = "locked_by")
    private UUID lockedBy;

    @Column(name = "locked_at")
    private LocalDateTime lockedAt;

    @Column(name = "leader_confirmed", nullable = false)
    @Builder.Default
    private boolean leaderConfirmed = false;

    // ─── Snapshot chong doi ten/phong (LLM doc thang, khoi JOIN) ───
    @Column(name = "reviewee_name")
    private String revieweeName;

    @Column(name = "evaluator_name")
    private String evaluatorName;

    @Column(name = "department_name")
    private String departmentName;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
