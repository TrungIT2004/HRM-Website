package com.minhtrung.hrm.payroll.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.payroll.entities.MonthlyPayrollSummary;

public interface MonthlyPayrollSummaryRepository extends JpaRepository<MonthlyPayrollSummary, UUID> {

    Optional<MonthlyPayrollSummary> findByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    boolean existsByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM MonthlyPayrollSummary m WHERE m.periodYear = :periodYear AND m.periodMonth BETWEEN :fromMonth AND :toMonth")
    void deleteByPeriodYearAndPeriodMonthBetween(@Param("periodYear") int periodYear, @Param("fromMonth") int fromMonth, @Param("toMonth") int toMonth);
}
