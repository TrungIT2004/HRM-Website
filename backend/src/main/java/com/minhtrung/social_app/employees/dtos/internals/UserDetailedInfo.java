package com.minhtrung.social_app.employees.dtos.internals;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

@AllArgsConstructor
@Getter
@Setter
public class UserDetailedInfo {
    // Từ User
    private UUID userId;
    private String email;
    private String firstName;
    private String lastName;
    private String gender;
    private LocalDate birthDate;
    private LocalDate joinedDate;
    private String profilePicUrl;
    private int annualLeaveDays;
    private int usedLeaveDays;
    // private String employeeCode;
    private String department;
    private String job;
    private double baseSalary;

    // Từ UserProfile
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

    // Từ UserBankAccount
    private String bankName;
    private String bankAccountNumber;

    // Từ UserContract
    private String contractType;
    private LocalDate contractStartDate;
    private LocalDate contractEndDate;
    private LocalDate probationEndDate;
}