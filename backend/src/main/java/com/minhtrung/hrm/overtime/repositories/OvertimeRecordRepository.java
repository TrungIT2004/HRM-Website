package com.minhtrung.hrm.overtime.repositories;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;

public interface OvertimeRecordRepository
        extends JpaRepository<OvertimeRecord, UUID>, JpaSpecificationExecutor<OvertimeRecord> {

    @Query("SELECT o FROM OvertimeRecord o WHERE o.requestor.userId = :userId AND o.approvedDate = :date AND o.status = :status")
    Optional<OvertimeRecord> findByRequestorIdAndApprovedDateAndStatus(@Param("userId") UUID userId, @Param("date") LocalDate date, @Param("status") OvertimeRecordStatus status);

    boolean existsByRequestor_UserIdAndApprovedDate(UUID userId, LocalDate approvedDate);

    /** Batch cho danh bạ: lấy OT hôm nay của nhiều người trong 1 query (tránh N+1). */
    List<OvertimeRecord> findByRequestor_UserIdInAndApprovedDateAndStatus(
            List<UUID> userIds, LocalDate approvedDate, OvertimeRecordStatus status);

    @Query(value = """
        SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (approved_end_time - approved_start_time))/3600), 0)
        FROM overtime_records
        WHERE requestor_id = :userId
        AND status = 'APPROVED'
        AND approved_start_time >= :start
        AND approved_start_time <= :end
    """, nativeQuery = true)
    double getTotalOvertimeHoursBetween(@Param("userId") UUID userId,
        @Param("start") LocalDateTime start,                                  
        @Param("end") LocalDateTime end);
                                    
    @Query("""
        SELECT o FROM OvertimeRecord o 
        WHERE o.requestor.userId = :userId 
          AND o.status = :status
          AND o.approvedDate BETWEEN :startOfMonth AND :endOfMonth
    """)
    List<OvertimeRecord> findAcceptedOvertimesByUserIdAndDateRange(
        @Param("userId") UUID userId,
        @Param("status") OvertimeRecordStatus status,
        @Param("startOfMonth") LocalDate startOfMonth,
        @Param("endOfMonth") LocalDate endOfMonth
    );

    @Query("""
        SELECT o FROM OvertimeRecord o 
        WHERE o.requestor.userId IN :userIds 
          AND o.status = :status
          AND o.approvedDate BETWEEN :startOfMonth AND :endOfMonth
    """)
    List<OvertimeRecord> findAcceptedOvertimesByUserIdsAndDateRange(
        @Param("userIds") List<UUID> userIds,
        @Param("status") OvertimeRecordStatus status,
        @Param("startOfMonth") LocalDate startOfMonth,
        @Param("endOfMonth") LocalDate endOfMonth
    );

    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM OvertimeRecord ot WHERE ot.approvedDate BETWEEN :startDate AND :endDate")
    void deleteByApprovedDateBetween(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
}
