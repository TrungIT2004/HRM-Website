package com.minhtrung.social_app.attendance.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.social_app.attendance.entities.WorkShift;

public interface WorkShiftRepository extends JpaRepository<WorkShift, UUID> {

    @Query("""
        SELECT s.dayOfWeek 
        FROM WorkShiftSchedule s 
        WHERE s.workShift.shiftId = :shiftId 
          AND s.isWorking = false
    """)
    List<Integer> getWeeklyRestDays(@Param("shiftId") UUID shiftId);
}