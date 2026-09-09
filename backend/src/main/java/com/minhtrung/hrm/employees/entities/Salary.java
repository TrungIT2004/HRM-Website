package com.minhtrung.hrm.employees.entities;

import java.time.LocalDate;
import java.util.UUID;

import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.employees.enums.PayFrequency;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
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
@Table(name = "salaries")
public class Salary {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID salaryId;
    
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "userId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_salary_user"))
    @JsonIgnore
    private User user;

    @Column(nullable = false)
    private double workDays;

    @Column(nullable = false)
    private double baseSalary;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private PayFrequency payFrequency;

    @Column(nullable = false)
    private LocalDate startDate;

    @Column()
    private LocalDate endDate;

    @Column(nullable = false)
    private boolean isActive = true;
}
