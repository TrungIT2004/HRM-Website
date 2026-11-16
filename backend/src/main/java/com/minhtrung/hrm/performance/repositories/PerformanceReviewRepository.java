package com.minhtrung.hrm.performance.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import com.minhtrung.hrm.performance.entities.PerformanceReview;
import com.minhtrung.hrm.performance.enums.PeriodType;

public interface PerformanceReviewRepository
        extends JpaRepository<PerformanceReview, UUID>, JpaSpecificationExecutor<PerformanceReview> {
    Optional<PerformanceReview> findByUser_UserIdAndPeriodTypeAndPeriodMonthAndPeriodYear(
            UUID userId, PeriodType periodType, int periodMonth, int periodYear);
}
