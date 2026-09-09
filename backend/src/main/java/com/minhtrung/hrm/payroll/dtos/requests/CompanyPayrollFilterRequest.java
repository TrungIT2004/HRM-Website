package com.minhtrung.hrm.payroll.dtos.requests;

import java.util.List;

import com.minhtrung.hrm.payroll.enums.PayrollStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class CompanyPayrollFilterRequest {
    private Integer periodMonth;
    private Integer periodYear;
    private PayrollStatus status;
    private String keyword;
    private List<String> departmentNames;
}
