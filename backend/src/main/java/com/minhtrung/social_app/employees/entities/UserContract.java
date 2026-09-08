package com.minhtrung.social_app.employees.entities;

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
    private UUID userId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId
    @JoinColumn(name = "userId", referencedColumnName = "userId")
    @JsonIgnore
    private User user;

    private String contractType;     
    private LocalDate contractStartDate;
    private LocalDate contractEndDate;
    private LocalDate probationEndDate;
}