package com.minhtrung.social_app.payroll.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import com.minhtrung.social_app.payroll.entities.Payroll;
import com.minhtrung.social_app.payroll.enums.PayrollStatus;

public interface PayrollRepository extends JpaRepository<Payroll, UUID>, JpaSpecificationExecutor<Payroll> {

    Optional<Payroll> findByUser_UserIdAndPeriodMonthAndPeriodYear(UUID userId, int periodMonth, int periodYear);

    boolean existsByUser_UserIdAndPeriodMonthAndPeriodYear(UUID userId, int periodMonth, int periodYear);

    boolean existsByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    List<Payroll> findByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    List<Payroll> findByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, PayrollStatus status);

    long countByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, PayrollStatus status);

    void deleteByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, PayrollStatus status);

    void deleteByPeriodYearAndPeriodMonthBetween(int periodYear, int fromMonth, int toMonth);
}
