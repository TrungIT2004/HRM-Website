package com.minhtrung.hrm.payroll.dtos.responses;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.hrm.payroll.enums.PayrollStatus;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class MonthlyPayrollSummaryResponse {
    private UUID summaryId;
    private int periodMonth;
    private int periodYear;
    private int totalEmployees;

    // Chi trả nhân viên
    private BigDecimal totalGrossPay;
    private BigDecimal totalNetPay;
    private BigDecimal totalBasicPay;
    private BigDecimal totalOvertimePay;
    private BigDecimal totalBonusPay;
    private BigDecimal totalAllowancePay;

    // Nghĩa vụ nhà nước
    private BigDecimal totalPersonalIncomeTax;
    private BigDecimal totalEmployeeInsurance;
    private BigDecimal totalCompanyInsurance;
    private BigDecimal totalUnionFee;

    // Tổng chi phí công ty
    private BigDecimal totalCompanyCost;

    private PayrollStatus status;
    private UUID approvedBy;
    private LocalDateTime approvedAt;
    private LocalDateTime createdAt;
}
