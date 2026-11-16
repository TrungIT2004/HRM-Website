package com.minhtrung.hrm.performance.entities;

import java.util.UUID;

import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
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
@Table(name = "performance_scores")
public class PerformanceScore {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID scoreId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "review_id", referencedColumnName = "reviewId", foreignKey = @ForeignKey(name = "fk_score_review"))
    @JsonIgnore
    private PerformanceReview review;

    @Column(name = "criterion_code", nullable = false, length = 10)
    private String criterionCode;

    @Column(name = "criterion_text", nullable = false)
    private String criterionText;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(name = "self_score")
    private Integer selfScore;

    @Column(name = "manager_score")
    private Integer managerScore;

    @Column(name = "note")
    private String note;
}
