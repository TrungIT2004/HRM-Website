package com.minhtrung.social_app.payroll.dtos.requests;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class EditPayrollRequest {
    private BigDecimal allowancePay;
    private BigDecimal bonusPay;
    private BigDecimal otherDeduction;
    private BigDecimal taxDeduction;
    private String note;
}
