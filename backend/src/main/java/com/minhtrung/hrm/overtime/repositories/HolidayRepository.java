package com.minhtrung.hrm.overtime.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.overtime.entities.Holiday;

public interface HolidayRepository extends JpaRepository<Holiday, UUID> {
    @Query(value = "SELECT EXISTS (SELECT 1 FROM holidays WHERE date = :date)", nativeQuery = true)
    boolean existsByDate(@Param("date") LocalDate date);

    @Query("""
        SELECT h.date
        FROM Holiday h
        WHERE h.date BETWEEN :fromDate AND :toDate
    """)
    List<LocalDate> getHolidayBetween(@Param("fromDate") LocalDate fromDate, @Param("toDate") LocalDate toDate);
}
