package com.minhtrung.hrm.attendance.entities;

import java.time.LocalTime;
import java.util.UUID;

import org.hibernate.annotations.UuidGenerator;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "work_shifts")
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class WorkShift {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID shiftId;

    @Column(nullable = false)
    private String name;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "rest_start_time")
    private LocalTime restStartTime;

    @Column(name = "rest_end_time")
    private LocalTime restEndTime;

    @Column(name = "is_monday", nullable = false)
    private boolean isMonday = true;

    @Column(name = "is_tuesday", nullable = false)
    private boolean isTuesday = true;

    @Column(name = "is_wednesday", nullable = false)
    private boolean isWednesday = true;

    @Column(name = "is_thursday", nullable = false)
    private boolean isThursday = true;

    @Column(name = "is_friday", nullable = false)
    private boolean isFriday = true;

    @Column(name = "is_saturday", nullable = false)
    private boolean isSaturday = false;

    @Column(name = "is_sunday", nullable = false)
    private boolean isSunday = false;
}