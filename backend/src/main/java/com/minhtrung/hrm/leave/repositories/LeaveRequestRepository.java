package com.minhtrung.hrm.leave.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.leave.dtos.responses.EmployeeLeaveReqResponse;
import com.minhtrung.hrm.leave.dtos.responses.LeaveRequestResponse;
import com.minhtrung.hrm.leave.dtos.responses.OneselfLeaveReqResponse;
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
        SELECT new com.minhtrung.hrm.leave.dtos.responses.OneselfLeaveReqResponse(
            lr.requestId,
            a.userId,
            CONCAT(a.firstName, ' ', a.lastName),
            lr.fromDate,
            lr.toDate,
            lr.paidLeaveDays,
            lr.reason,
            lr.rejectionReason,
            lr.status
        )
        FROM LeaveRequest lr
        JOIN lr.approver a
        WHERE lr.requestor.userId = :userId
    """)
    List<OneselfLeaveReqResponse> getOnesefLeaveRequests(
        @Param("userId") UUID userId
    );

    @Query("""
        SELECT new com.minhtrung.hrm.leave.dtos.responses.EmployeeLeaveReqResponse(
            lr.requestId,
            r.userId,
            CONCAT(r.firstName, ' ', r.lastName),
            j.title,
            lr.fromDate,
            lr.toDate,
            lr.paidLeaveDays,
            lr.reason,
            lr.rejectionReason,
            lr.status
        )
        FROM LeaveRequest lr
        JOIN lr.requestor r
        JOIN r.department d
        JOIN r.job j
        WHERE d.departmentId = :departmentId
          AND lr.fromDate <= :endDate
          AND lr.toDate >= :startDate
          AND lr.status = :status
          AND r.userId != :departmentHeadId
    """)
    List<EmployeeLeaveReqResponse> getEmployeeLeaveRequests(
        @Param("departmentId") UUID departmentId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("status") LeaveRequestStatus status,
        @Param("departmentHeadId") UUID departmentHeadId
    );

    @Query("""
        SELECT new com.minhtrung.hrm.leave.dtos.responses.LeaveRequestResponse(
            lr.requestId,
            r.userId,
            CONCAT(r.firstName, ' ', r.lastName),
            rd.name,
            rj.title,
            a.userId,
            CONCAT(a.firstName, ' ', a.lastName),
            ad.name,
            aj.title,
            lr.fromDate,
            lr.toDate,
            lr.paidLeaveDays,
            lr.reason,
            lr.rejectionReason,
            lr.status
        )
        FROM LeaveRequest lr
        JOIN lr.requestor r
        JOIN r.department rd
        JOIN r.job rj
        LEFT JOIN lr.approver a
        LEFT JOIN a.department ad
        LEFT JOIN a.job aj
        WHERE lr.fromDate <= :endDate
        AND lr.toDate >= :startDate
        AND lr.status = :status
        AND r.userId IN (:departmentHeadIdList)
    """)
    List<LeaveRequestResponse> getDepartmentHeadsLeaveRequests(
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("status") LeaveRequestStatus status,    
        @Param("departmentHeadIdList") List<UUID> departmentHeadIdList
    );

    @Query("""
        SELECT new com.minhtrung.hrm.leave.dtos.responses.LeaveRequestResponse(
            lr.requestId,
            r.userId,
            CONCAT(r.firstName, ' ', r.lastName),
            rd.name,
            rj.title,
            a.userId,
            CONCAT(a.firstName, ' ', a.lastName),
            ad.name,
            aj.title,
            lr.fromDate,
            lr.toDate,
            lr.paidLeaveDays,
            lr.reason,
            lr.rejectionReason,
            lr.status
        )
        FROM LeaveRequest lr
        LEFT JOIN lr.requestor r
        LEFT JOIN r.department rd
        LEFT JOIN r.job rj
        LEFT JOIN lr.approver a
        LEFT JOIN a.department ad
        LEFT JOIN a.job aj
        WHERE (:startDate IS NULL OR lr.toDate >= :startDate)
        AND (:endDate IS NULL OR lr.fromDate <= :endDate)
        AND rd.departmentId = COALESCE(:departmentId, rd.departmentId)
        AND lr.status = COALESCE(:status, lr.status)
    """)
    List<LeaveRequestResponse> getAllLeaveRequests(
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("departmentId") UUID departmentId,
        @Param("status") LeaveRequestStatus status
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