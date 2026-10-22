package com.minhtrung.hrm.attendance.entities;

import java.time.LocalTime;
import java.util.UUID;

import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "work_shift_schedules", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"shift_id", "day_of_week"})
})
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class WorkShiftSchedule {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID scheduleId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "shift_id", nullable = false, foreignKey = @ForeignKey(name = "fk_shift_schedules"))
    @JsonIgnore
    private WorkShift workShift;

    @Column(name = "day_of_week", nullable = false)
    private Integer dayOfWeek; // 1 = Thứ 2, 2 = Thứ 3, ..., 7 = Chủ nhật

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "rest_start_time")
    private LocalTime restStartTime;

    @Column(name = "rest_end_time")
    private LocalTime restEndTime;

    @Column(name = "is_working", nullable = false)
    @Builder.Default
    private boolean isWorking = true;
}