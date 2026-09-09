package com.minhtrung.hrm.attendance.entities;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "work_shifts")
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class WorkShift {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID shiftId;

    @Column(nullable = false)
    private String name;

    @OneToMany(mappedBy = "workShift", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnore
    @Builder.Default
    private List<WorkShiftSchedule> schedules = new ArrayList<>();
}