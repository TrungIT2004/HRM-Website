package com.minhtrung.social_app.payroll.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.social_app.payroll.entities.MonthlyPayrollSummary;

public interface MonthlyPayrollSummaryRepository extends JpaRepository<MonthlyPayrollSummary, UUID> {

    Optional<MonthlyPayrollSummary> findByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    boolean existsByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    void deleteByPeriodYearAndPeriodMonthBetween(int periodYear, int fromMonth, int toMonth);
}
