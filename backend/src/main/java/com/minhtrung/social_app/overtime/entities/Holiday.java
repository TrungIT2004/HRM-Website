package com.minhtrung.social_app.overtime.entities;

import java.time.LocalDate;
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

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "holidays")
public class Holiday {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID holidayId;

    @Column(nullable = false)
    private LocalDate date;

    @Column(nullable = false)
    private String description;
}
