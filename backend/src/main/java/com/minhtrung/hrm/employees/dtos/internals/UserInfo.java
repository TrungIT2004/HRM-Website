package com.minhtrung.hrm.employees.dtos.internals;

import java.time.LocalDate;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class UserInfo {
    private UUID userId;
    private String firstName;
    private String lastName;
    private String gender;
    private LocalDate birthDate;
    private String profilePicUrl;
    private int annualLeaveDays = 12;
    private int usedLeaveDays = 0;
    private String department;
    private String job;
}
