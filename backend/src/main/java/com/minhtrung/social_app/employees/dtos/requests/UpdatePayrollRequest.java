package com.minhtrung.social_app.employees.dtos.requests;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdatePayrollRequest {

    // Lương cơ bản (salaries)
    private Long baseSalary;
    private String payFrequency; // HOURLY, WEEKLY, MONTHLY
    private Double workDays;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate endDate;

    private Boolean isActive;

    // Tài khoản ngân hàng (user_bank_accounts)
    private String bankName;
    private String bankAccountNumber;
}
