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
public class StaffPayrollResponse {
    private UUID payrollId;
    private int periodMonth;
    private int periodYear;

    // Lương cơ sở
    private BigDecimal baseSalary;
    private BigDecimal hourlyRate;

    // Snapshot công (lấy từ timesheet)
    private int standardWorkingDays;
    private BigDecimal actualWorkedDays;
    private BigDecimal actualWorkHours;
    private BigDecimal paidOvertimeHours;

    // Thu nhập
    private BigDecimal basicPay;
    private BigDecimal overtimePay;
    private BigDecimal allowancePay;
    private BigDecimal bonusPay;
    private BigDecimal grossPay;

    // Khấu trừ
    private BigDecimal insuranceDeduction;
    private BigDecimal taxDeduction;
    private BigDecimal otherDeduction;
    private BigDecimal totalDeduction;

    // Thực nhận & trạng thái
    private BigDecimal netPay;
    private PayrollStatus status;
    private String note;
    private LocalDateTime calculatedAt;
    private LocalDateTime paidAt;
}
