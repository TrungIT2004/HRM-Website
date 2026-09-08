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
@Table(name = "user_profiles")
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID userId;  // khóa chính, đồng thời là khóa ngoại

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId
    @JoinColumn(name = "userId", referencedColumnName = "userId")
    @JsonIgnore
    private User user;

    private String phoneNumber;
    private String personalEmail;
    private String placeOfBirth;
    private String maritalStatus;   
    private String nationality;
    private String citizenIdNumber;
    private String socialInsuranceNumber;
    private String taxIdentificationNumber;
    private LocalDate socialInsuranceStartDate;
    private String emergencyContactName;
    private String emergencyContactPhone;
}