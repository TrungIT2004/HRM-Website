package com.minhtrung.social_app.payroll.dtos.requests;

import com.minhtrung.social_app.payroll.enums.PayrollStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class StaffPayrollFilterRequest {
    private Integer periodMonth;
    private Integer periodYear;
    private PayrollStatus status;
}
