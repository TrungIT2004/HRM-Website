package com.minhtrung.social_app.employees.dtos.internals;

import java.time.LocalDate;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class UserContractInfo {
    private UUID userId;
    private String contractType;     
    private LocalDate contractStartDate;
    private LocalDate contractEndDate;
    private LocalDate probationEndDate;
}
