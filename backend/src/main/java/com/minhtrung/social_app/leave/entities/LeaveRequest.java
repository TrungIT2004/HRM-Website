package com.minhtrung.social_app.leave.entities;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.social_app.employees.entities.User;
import com.minhtrung.social_app.leave.enums.LeaveRequestStatus;

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
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "leave_requests")
public class LeaveRequest {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID requestId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requestorId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_leave_request_user"))
    @JsonIgnore
    private User requestor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approverId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_leave_request_user"))
    @JsonIgnore
    private User approver;

    @Column(name = "from_date", nullable = false)
    private LocalDate fromDate;

    @Column(name = "to_date", nullable = false)
    private LocalDate toDate;

    @Column(nullable = false)
    private String reason;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "paid_leave_days", nullable = false)
    private int paidLeaveDays = 0; 

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private LeaveRequestStatus status = LeaveRequestStatus.pending;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public UUID getRequestorId() {
        return this.requestor != null ? requestor.getUserId() : null;
    }

    public UUID getApproverId() {
        return this.approver != null ? approver.getUserId() : null;
    }
}
