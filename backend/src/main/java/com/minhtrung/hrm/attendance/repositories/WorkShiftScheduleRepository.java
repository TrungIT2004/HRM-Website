package com.minhtrung.hrm.attendance.repositories;

import com.minhtrung.hrm.attendance.entities.WorkShiftSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WorkShiftScheduleRepository extends JpaRepository<WorkShiftSchedule, UUID> {
    List<WorkShiftSchedule> findByWorkShift_ShiftId(UUID shiftId);
    Optional<WorkShiftSchedule> findByWorkShift_ShiftIdAndDayOfWeek(UUID shiftId, Integer dayOfWeek);

    int countByWorkShift_ShiftId(UUID shiftId);

    void deleteAllByWorkShift_ShiftId(UUID shiftId);
}