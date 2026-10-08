package com.minhtrung.hrm.performance.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.performance.entities.PerformanceScore;

public interface PerformanceScoreRepository extends JpaRepository<PerformanceScore, UUID> {
    List<PerformanceScore> findByReview_ReviewIdOrderBySortOrderAsc(UUID reviewId);
}
