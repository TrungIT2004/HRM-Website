package com.minhtrung.social_app.payroll.entities;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.minhtrung.social_app.payroll.enums.PayrollStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
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
    name = "monthly_payroll_summaries",
    uniqueConstraints = @UniqueConstraint(name = "uk_summary_period", columnNames = {"period_month", "period_year"})
)
public class MonthlyPayrollSummary {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID summaryId;

    @Column(name = "period_month", nullable = false)
    private int periodMonth;

    @Column(name = "period_year", nullable = false)
    private int periodYear;

    @Column(name = "total_employees", nullable = false)
    @Builder.Default
    private int totalEmployees = 0;

    // ─── Tiền trả cho Nhân viên ────────────────────────────────
    @Column(name = "total_gross_pay", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalGrossPay = BigDecimal.ZERO;

    @Column(name = "total_net_pay", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalNetPay = BigDecimal.ZERO;

    @Column(name = "total_basic_pay", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBasicPay = BigDecimal.ZERO;

    @Column(name = "total_overtime_pay", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalOvertimePay = BigDecimal.ZERO;

    @Column(name = "total_bonus_pay", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBonusPay = BigDecimal.ZERO;

    @Column(name = "total_allowance_pay", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalAllowancePay = BigDecimal.ZERO;

    // ─── Tiền nộp Cơ quan Nhà nước ─────────────────────────────
    @Column(name = "total_personal_income_tax", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalPersonalIncomeTax = BigDecimal.ZERO;

    @Column(name = "total_employee_insurance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalEmployeeInsurance = BigDecimal.ZERO;

    @Column(name = "total_company_insurance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalCompanyInsurance = BigDecimal.ZERO;

    @Column(name = "total_union_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalUnionFee = BigDecimal.ZERO;

    // ─── Tổng chi phí công ty gánh ─────────────────────────────
    @Column(name = "total_company_cost", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalCompanyCost = BigDecimal.ZERO;

    // ─── Trạng thái & Phê duyệt ────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private PayrollStatus status = PayrollStatus.DRAFT;

    @Column(name = "approved_by")
    private UUID approvedBy;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
