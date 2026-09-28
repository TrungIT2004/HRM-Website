package com.minhtrung.hrm.payroll.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.payroll.entities.Payroll;
import com.minhtrung.hrm.payroll.enums.PayrollStatus;

public interface PayrollRepository extends JpaRepository<Payroll, UUID>, JpaSpecificationExecutor<Payroll> {

    Optional<Payroll> findByUser_UserIdAndPeriodMonthAndPeriodYear(UUID userId, int periodMonth, int periodYear);

    boolean existsByUser_UserIdAndPeriodMonthAndPeriodYear(UUID userId, int periodMonth, int periodYear);

    boolean existsByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    List<Payroll> findByPeriodMonthAndPeriodYear(int periodMonth, int periodYear);

    List<Payroll> findByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, PayrollStatus status);

    long countByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, PayrollStatus status);

    void deleteByPeriodMonthAndPeriodYearAndStatus(int periodMonth, int periodYear, PayrollStatus status);

    /** Xoá DRAFT chỉ trong nhóm nhân viên đang lọc — tránh mất bản ghi của phòng ban khác. */
    void deleteByPeriodMonthAndPeriodYearAndStatusAndUser_UserIdIn(
            int periodMonth, int periodYear, PayrollStatus status, List<UUID> userIds);

    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM Payroll p WHERE p.periodYear = :periodYear AND p.periodMonth BETWEEN :fromMonth AND :toMonth")
    void deleteByPeriodYearAndPeriodMonthBetween(@Param("periodYear") int periodYear, @Param("fromMonth") int fromMonth, @Param("toMonth") int toMonth);
}
