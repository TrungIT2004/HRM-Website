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

import com.minhtrung.hrm.overtime.dtos.responses.EmployeeOTRecordResponse;
import com.minhtrung.hrm.overtime.dtos.responses.OTRecordResponse;
import com.minhtrung.hrm.overtime.dtos.responses.OneselfOTRecordResponse;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;

public interface OvertimeRecordRepository
        extends JpaRepository<OvertimeRecord, UUID>, JpaSpecificationExecutor<OvertimeRecord> {

    @Query("SELECT o FROM OvertimeRecord o WHERE o.requestor.userId = :userId AND o.approvedDate = :date AND o.status = :status")
    Optional<OvertimeRecord> findByRequestorIdAndApprovedDateAndStatus(@Param("userId") UUID userId, @Param("date") LocalDate date, @Param("status") OvertimeRecordStatus status);

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
        SELECT new com.minhtrung.hrm.overtime.dtos.responses.OneselfOTRecordResponse(
            ot.overtimeRecordId,
            u.userId,
            CONCAT(u.firstName, ' ', u.lastName),
            ot.approvedStartTime,
            ot.approvedEndTime,
            ot.clockInTime,
            ot.clockOutTime,
            ot.isNightTime,
            ot.isWeekend,
            ot.isHoliday,
            ot.reason,
            ot.rejectionReason,
            ot.status
        )
        FROM OvertimeRecord ot 
        LEFT JOIN ot.approver u
        WHERE ot.requestor.userId = :userId
        AND ot.approvedStartTime >= COALESCE(:startDateTime, ot.approvedStartTime)
        AND ot.approvedEndTime <= COALESCE(:endDateTime, ot.approvedEndTime)
        AND ot.status = COALESCE(:status, ot.status)
    """)
    List<OneselfOTRecordResponse> getSelfOTRecords(
        @Param("userId") UUID userId, 
        @Param("startDateTime") LocalDateTime startDateTime, 
        @Param("endDateTime") LocalDateTime endDateTime,
        @Param("status") OvertimeRecordStatus status
    );

    @Query("""
        SELECT new com.minhtrung.hrm.overtime.dtos.responses.EmployeeOTRecordResponse(
            ot.overtimeRecordId,
                            
            r.userId,
            CONCAT(r.firstName, ' ', r.lastName),
            rj.title,
                    
            ot.approvedStartTime,
            ot.approvedEndTime,
            ot.clockInTime,
            ot.clockOutTime,
            ot.isNightTime,
            ot.isWeekend,
            ot.isHoliday,
            ot.reason,
            ot.rejectionReason,
            ot.status
        )
        FROM OvertimeRecord ot
        JOIN ot.requestor r
        JOIN r.job rj
        WHERE ot.approvedStartTime >= COALESCE(:startDateTime, ot.approvedStartTime)
        AND ot.approvedEndTime <= COALESCE(:endDateTime, ot.approvedEndTime)
        AND r.department.departmentId = COALESCE(:departmentId, r.department.departmentId)
        AND ot.status = COALESCE(:status, ot.status)
    """)
    List<EmployeeOTRecordResponse> getEmployeesOTRecords(
        @Param("startDateTime") LocalDateTime startDateTime, 
        @Param("endDateTime") LocalDateTime endDateTime,
        @Param("departmentId") UUID departmentId,
        @Param("status") OvertimeRecordStatus status);


    @Query("""
        SELECT new com.minhtrung.hrm.overtime.dtos.responses.OTRecordResponse(
            ot.overtimeRecordId,
                            
            r.userId,
            CONCAT(r.firstName, ' ', r.lastName),
            rd.name,
            rj.title,
                    
            a.userId,
            CONCAT(a.firstName, ' ', a.lastName),
            ad.name,
            aj.title,
            
            ot.approvedStartTime,
            ot.approvedEndTime,
            ot.clockInTime,
            ot.clockOutTime,
            ot.isNightTime,
            ot.isWeekend,
            ot.isHoliday,
            ot.reason,
            ot.rejectionReason,
            ot.status
        )
        FROM OvertimeRecord ot
        JOIN ot.requestor r
        LEFT JOIN r.department rd
        LEFT JOIN r.job rj
        LEFT JOIN ot.approver a
        LEFT JOIN a.department ad
        LEFT JOIN a.job aj
        WHERE ot.approvedStartTime >= COALESCE(:startDateTime, ot.approvedStartTime)
        AND ot.approvedEndTime <= COALESCE(:endDateTime, ot.approvedEndTime)
        AND rd.departmentId = COALESCE(:departmentId, rd.departmentId)
        AND ot.status = COALESCE(:status, ot.status)
        AND r.userId IN (:departmentHeadIdList)
    """)
    List<OTRecordResponse> getDepartmentHeadsOTRecords(
        @Param("startDateTime") LocalDateTime startDateTime, 
        @Param("endDateTime") LocalDateTime endDateTime,
        @Param("departmentId") UUID departmentId,
        @Param("status") OvertimeRecordStatus status,
        @Param("departmentHeadIdList") List<UUID> departmentHeadIdList);

    @Query("""
        SELECT new com.minhtrung.hrm.overtime.dtos.responses.OTRecordResponse(
            ot.overtimeRecordId,
                            
            r.userId,
            CONCAT(r.firstName, ' ', r.lastName),
            rd.name,
            rj.title,
                    
            a.userId,
            CONCAT(a.firstName, ' ', a.lastName),
            ad.name,
            aj.title,
            
            ot.approvedStartTime,
            ot.approvedEndTime,
            ot.clockInTime,
            ot.clockOutTime,
            ot.isNightTime,
            ot.isWeekend,
            ot.isHoliday,
            ot.reason,
            ot.rejectionReason,
            ot.status
        )
        FROM OvertimeRecord ot
        JOIN ot.requestor r
        LEFT JOIN r.department rd
        LEFT JOIN r.job rj
        LEFT JOIN ot.approver a
        LEFT JOIN a.department ad
        LEFT JOIN a.job aj
        WHERE ot.approvedStartTime >= COALESCE(:startDateTime, ot.approvedStartTime)
        AND ot.approvedEndTime <= COALESCE(:endDateTime, ot.approvedEndTime)
        AND rd.departmentId = COALESCE(:departmentId, rd.departmentId)
        AND ot.status = COALESCE(:status, ot.status)
    """)
    List<OTRecordResponse> getOTRecords(
        @Param("startDateTime") LocalDateTime startDateTime, 
        @Param("endDateTime") LocalDateTime endDateTime,
        @Param("departmentId") UUID departmentId,
        @Param("status") OvertimeRecordStatus status);

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

    void deleteByApprovedDateBetween(LocalDate startDate, LocalDate endDate);
}
