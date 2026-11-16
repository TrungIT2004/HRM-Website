package com.minhtrung.hrm.leave.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.leave.entities.LeaveRequest;
import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;

public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, UUID>, JpaSpecificationExecutor<LeaveRequest> {

    @Query("""
        SELECT COUNT(lr) > 0
        FROM LeaveRequest lr
        WHERE lr.requestor.userId = :userId
          AND lr.status IN :statuses
          AND lr.fromDate <= :toDate
          AND lr.toDate >= :fromDate
    """)
    boolean existsOverlappingLeaveRequest(
        @Param("userId") UUID userId,
        @Param("fromDate") LocalDate fromDate,
        @Param("toDate") LocalDate toDate,
        @Param("statuses") List<LeaveRequestStatus> statuses
    );

    @Query("""
        SELECT l FROM LeaveRequest l 
        WHERE l.requestor.userId = :userId 
          AND l.status = :status
          AND l.fromDate <= :endOfMonth AND l.toDate >= :startOfMonth
    """)
    List<LeaveRequest> findAcceptedLeavesByUserIdAndDateRange(
        @Param("userId") UUID userId,
        @Param("status") LeaveRequestStatus status,
        @Param("startOfMonth") LocalDate startOfMonth,
        @Param("endOfMonth") LocalDate endOfMonth
    );

    @Query("""
        SELECT l FROM LeaveRequest l 
        WHERE l.requestor.userId IN :userIds 
          AND l.status = :status
          AND l.fromDate <= :endOfMonth AND l.toDate >= :startOfMonth
    """)
    List<LeaveRequest> findAcceptedLeavesByUserIdsAndDateRange(
        @Param("userIds") List<UUID> userIds,
        @Param("status") LeaveRequestStatus status,
        @Param("startOfMonth") LocalDate startOfMonth,
        @Param("endOfMonth") LocalDate endOfMonth
    );

    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM LeaveRequest lr WHERE lr.fromDate <= :endDate AND lr.toDate >= :startDate")
    void deleteLeavesBetween(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
}