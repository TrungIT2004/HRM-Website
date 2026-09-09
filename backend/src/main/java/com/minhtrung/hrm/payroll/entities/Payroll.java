package com.minhtrung.hrm.payroll.entities;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.attendance.entities.MonthlyTimesheet;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.payroll.enums.PayrollStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
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
@Entity
@Table(
    name = "payrolls",
    uniqueConstraints = @UniqueConstraint(name = "uk_payroll_user_period", columnNames = {"user_id", "period_month", "period_year"})
)
public class Payroll {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID payrollId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_payroll_user"))
    @JsonIgnore
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "timesheet_id", referencedColumnName = "timesheetId", foreignKey = @ForeignKey(name = "fk_payroll_timesheet"))
    @JsonIgnore
    private MonthlyTimesheet timesheet;

    @Column(name = "period_month", nullable = false)
    private int periodMonth;

    @Column(name = "period_year", nullable = false)
    private int periodYear;

    // ─── Lương cơ sở ───────────────────────────────────────────
    @Column(name = "base_salary", nullable = false, precision = 15, scale = 2)
    private BigDecimal baseSalary;

    @Column(name = "hourly_rate", nullable = false, precision = 15, scale = 2)
    private BigDecimal hourlyRate;

    // ─── Các khoản thu nhập ────────────────────────────────────
    @Column(name = "basic_pay", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal basicPay = BigDecimal.ZERO;

    @Column(name = "overtime_pay", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal overtimePay = BigDecimal.ZERO;

    @Column(name = "allowance_pay", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal allowancePay = BigDecimal.ZERO;

    @Column(name = "bonus_pay", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal bonusPay = BigDecimal.ZERO;

    @Column(name = "gross_pay", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal grossPay = BigDecimal.ZERO;

    // ─── Các khoản khấu trừ ────────────────────────────────────
    @Column(name = "insurance_deduction", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal insuranceDeduction = BigDecimal.ZERO;

    @Column(name = "tax_deduction", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal taxDeduction = BigDecimal.ZERO;

    @Column(name = "other_deduction", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal otherDeduction = BigDecimal.ZERO;

    @Column(name = "total_deduction", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalDeduction = BigDecimal.ZERO;

    // ─── Thực nhận & Trạng thái ────────────────────────────────
    @Column(name = "net_pay", nullable = false, precision = 15, scale = 2)
    private BigDecimal netPay;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private PayrollStatus status = PayrollStatus.DRAFT;

    @Column(name = "note")
    private String note;

    @Column(name = "calculated_at")
    private LocalDateTime calculatedAt;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public UUID getUserId() {
        return user != null ? user.getUserId() : null;
    }

    public UUID getTimesheetId() {
        return timesheet != null ? timesheet.getTimesheetId() : null;
    }
}
