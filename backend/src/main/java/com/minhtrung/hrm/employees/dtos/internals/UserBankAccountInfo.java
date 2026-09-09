package com.minhtrung.hrm.employees.dtos.internals;

import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class UserBankAccountInfo {
    private UUID userId;
    private String bankName;
    private String bankAccountNumber;
}
