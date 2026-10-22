package com.minhtrung.hrm.resignation.entities;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.resignation.enums.ResignationStatus;

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
@Table(name = "resignation_requests")
public class ResignationRequest {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID resignationId;

    // ─── Nhân sự liên quan ──────────────────────────────────────
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_resignation_user"))
    @JsonIgnore
    private User user;

    // ─── Thông tin ngày nghỉ & Lý do ────────────────────────────
    @Column(name = "submitted_time", nullable = false)
    private LocalDateTime submittedTime;

    @Column(name = "last_working_date", nullable = false)
    private LocalDate lastWorkingDate;

    @Column(name = "reason", nullable = false, length = 500)
    private String reason;

    // ─── Trạng thái & Phê duyệt Cấp 1 (Trưởng phòng) ────────────
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private ResignationStatus status = ResignationStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manager_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_resignation_manager"))
    @JsonIgnore
    private User manager;

    @Column(name = "manager_comment", length = 255)
    private String managerComment;

    @Column(name = "manager_approved_at")
    private LocalDateTime managerApprovedAt;

    // ─── Phê duyệt Cấp 2 (HR hoặc Ban Giám Đốc) ─────────────────
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hr_or_executive_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_resignation_hr"))
    @JsonIgnore
    private User executive;

    @Column(name = "hr_comment", length = 255)
    private String executiveComment;

    @Column(name = "hr_approved_at")
    private LocalDateTime executiveApprovedAt;

    // ─── Audit timestamps ───────────────────────────────────────
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public UUID getUserId() {
        return user != null ? user.getUserId() : null;
    }
}
