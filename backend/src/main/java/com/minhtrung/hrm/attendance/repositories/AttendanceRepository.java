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

    /** attendances tham chiếu work_shifts — xoá ca sẽ mất lịch sử chấm công. */
    long countByShift_ShiftId(UUID shiftId);

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

    @Query("""
        SELECT a FROM Attendance a
        JOIN FETCH a.user u
        LEFT JOIN FETCH u.department d
        WHERE a.workDate BETWEEN :startDate AND :endDate
    """)
    List<Attendance> findAllByWorkDateBetween(
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    @Query("SELECT MAX(a.workDate) FROM Attendance a")
    java.util.Optional<LocalDate> findMaxWorkDate();

    // ponytail: ngày công mới nhất đã có dữ liệu thật (bỏ qua dòng NOT_CHECKED cron tạo sẵn)
    @Query("SELECT MAX(a.workDate) FROM Attendance a WHERE a.status <> com.minhtrung.hrm.attendance.enums.AttendanceStatus.NOT_CHECKED")
    java.util.Optional<LocalDate> findMaxCheckedWorkDate();

    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM Attendance a WHERE a.workDate BETWEEN :startDate AND :endDate")
    void deleteByWorkDateBetween(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
}