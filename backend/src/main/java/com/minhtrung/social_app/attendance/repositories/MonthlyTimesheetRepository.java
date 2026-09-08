package com.minhtrung.social_app.attendance.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import com.minhtrung.social_app.attendance.entities.MonthlyTimesheet;
import com.minhtrung.social_app.attendance.enums.TimesheetStatus;

public interface MonthlyTimesheetRepository extends JpaRepository<MonthlyTimesheet, UUID>, JpaSpecificationExecutor<MonthlyTimesheet> {

    Optional<MonthlyTimesheet> findByUser_UserIdAndPeriodMonthAndPeriodYear(UUID userId, int periodMonth, int periodYear);

    boolean existsByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    List<MonthlyTimesheet> findByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    List<MonthlyTimesheet> findByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    boolean existsByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    long countByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    void deleteByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    void deleteByPeriodYearAndPeriodMonthBetween(int periodYear, int fromMonth, int toMonth);
}
