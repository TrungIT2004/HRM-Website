package com.minhtrung.hrm.attendance.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.attendance.entities.MonthlyTimesheet;
import com.minhtrung.hrm.attendance.enums.TimesheetStatus;

public interface MonthlyTimesheetRepository extends JpaRepository<MonthlyTimesheet, UUID>, JpaSpecificationExecutor<MonthlyTimesheet> {

    Optional<MonthlyTimesheet> findByUser_UserIdAndPeriodMonthAndPeriodYear(UUID userId, int periodMonth, int periodYear);

    boolean existsByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    List<MonthlyTimesheet> findByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    List<MonthlyTimesheet> findByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    /** Lấy đúng nhóm nhân viên được chọn trên bảng — dùng cho chốt sổ theo vùng chọn. */
    List<MonthlyTimesheet> findByPeriodMonthAndPeriodYearAndUser_UserIdIn(int periodMonth, int periodYear, List<UUID> userIds);

    boolean existsByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    long countByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    @org.springframework.data.jpa.repository.Modifying
    void deleteByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, TimesheetStatus status);

    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM MonthlyTimesheet m WHERE m.periodYear = :periodYear AND m.periodMonth BETWEEN :fromMonth AND :toMonth")
    void deleteByPeriodYearAndPeriodMonthBetween(@Param("periodYear") int periodYear, @Param("fromMonth") int fromMonth, @Param("toMonth") int toMonth);
}
