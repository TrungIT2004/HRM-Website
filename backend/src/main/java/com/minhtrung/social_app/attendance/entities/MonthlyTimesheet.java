package com.minhtrung.social_app.attendance.entities;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.social_app.attendance.enums.TimesheetStatus;
import com.minhtrung.social_app.employees.entities.User;

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
    name = "monthly_timesheets",
    uniqueConstraints = @UniqueConstraint(name = "uk_timesheet_user_period", columnNames = {"user_id", "period_month", "period_year"})
)
public class MonthlyTimesheet {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID timesheetId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_timesheet_user"))
    @JsonIgnore
    private User user;

    @Column(name = "period_month", nullable = false)
    private int periodMonth;

    @Column(name = "period_year", nullable = false)
    private int periodYear;

    // ─── Dữ liệu Chấm công ──────────────────────────────────────
    @Column(name = "standard_working_days", nullable = false)
    private int standardWorkingDays;

    @Column(name = "actual_worked_days", nullable = false, precision = 4, scale = 2)
    @Builder.Default
    private BigDecimal actualWorkedDays = BigDecimal.ZERO;

    @Column(name = "actual_work_hours", nullable = false, precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal actualWorkHours = BigDecimal.ZERO;

    @Column(name = "late_count", nullable = false)
    @Builder.Default
    private int lateCount = 0;

    @Column(name = "total_late_minutes", nullable = false)
    @Builder.Default
    private int totalLateMinutes = 0;

    @Column(name = "early_departure_count", nullable = false)
    @Builder.Default
    private int earlyDepartureCount = 0;

    @Column(name = "absent_days", nullable = false, precision = 4, scale = 2)
    @Builder.Default
    private BigDecimal absentDays = BigDecimal.ZERO;

    // ─── Dữ liệu Nghỉ phép ─────────────────────────────────────
    @Column(name = "paid_leave_days", nullable = false, precision = 4, scale = 2)
    @Builder.Default
    private BigDecimal paidLeaveDays = BigDecimal.ZERO;

    @Column(name = "unpaid_leave_days", nullable = false, precision = 4, scale = 2)
    @Builder.Default
    private BigDecimal unpaidLeaveDays = BigDecimal.ZERO;

    // ─── Dữ liệu Tăng ca (OT) ──────────────────────────────────
    @Column(name = "total_actual_ot_hours", nullable = false, precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal totalActualOtHours = BigDecimal.ZERO;

    @Column(name = "total_paid_ot_hours", nullable = false, precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal totalPaidOtHours = BigDecimal.ZERO;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "ot_details", columnDefinition = "jsonb")
    private String otDetails;

    // ─── Trạng thái & Kiểm toán ────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private TimesheetStatus status = TimesheetStatus.DRAFT;

    @Column(name = "note")
    private String note;

    @Column(name = "locked_at")
    private LocalDateTime lockedAt;

    @Column(name = "locked_by")
    private UUID lockedBy;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public UUID getUserId() {
        return user != null ? user.getUserId() : null;
    }
}
