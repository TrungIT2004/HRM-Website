package com.minhtrung.hrm.attendance.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.attendance.entities.Attendance;

public interface AttendanceRepository extends JpaRepository<Attendance, UUID>, JpaSpecificationExecutor<Attendance> {
    List<Attendance> findByWorkDate(LocalDate workDate);

    @Query("""
        SELECT a
        FROM Attendance a
        WHERE a.user.userId = :userId AND a.workDate = :workDate
    """)
    Optional<Attendance> findUsersTodayAttendance(@Param("userId") UUID userId, @Param("workDate") LocalDate workDate);

    @Query("""
        SELECT a FROM Attendance a 
        WHERE a.user.userId = :userId 
          AND a.workDate BETWEEN :startOfMonth AND :endOfMonth
    """)
    List<Attendance> findByUserIdAndDateRange(
        @Param("userId") UUID userId,
        @Param("startOfMonth") LocalDate startOfMonth,
        @Param("endOfMonth") LocalDate endOfMonth
    );

    @Query("""
        SELECT a FROM Attendance a 
        WHERE a.user.userId IN :userIds 
          AND a.workDate BETWEEN :startOfMonth AND :endOfMonth
    """)
    List<Attendance> findAttendancesByUserIdsAndDateRange(
        @Param("userIds") List<UUID> userIds,
        @Param("startOfMonth") LocalDate startOfMonth,
        @Param("endOfMonth") LocalDate endOfMonth
    );

    void deleteByWorkDateBetween(LocalDate startDate, LocalDate endDate);
}