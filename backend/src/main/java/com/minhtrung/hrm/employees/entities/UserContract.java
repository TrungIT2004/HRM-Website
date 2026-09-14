package com.minhtrung.hrm.employees.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonIgnore;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "user_contracts")
public class UserContract {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "contract_id")
    private UUID contractId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", referencedColumnName = "userId")
    @JsonIgnore
    private User user;

    @Column(name = "contract_type")
    private String contractType;     

    @Column(name = "contract_start_date")
    private LocalDate contractStartDate;

    @Column(name = "contract_end_date")
    private LocalDate contractEndDate;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;
}