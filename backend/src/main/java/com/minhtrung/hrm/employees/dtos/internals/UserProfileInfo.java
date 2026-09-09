package com.minhtrung.hrm.employees.dtos.internals;

import java.time.LocalDate;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class UserProfileInfo {
    private UUID userId;
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
