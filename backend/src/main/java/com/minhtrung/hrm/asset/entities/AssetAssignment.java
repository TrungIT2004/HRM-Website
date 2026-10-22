package com.minhtrung.hrm.asset.entities;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.asset.enums.AssignmentStatus;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.User;

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
@Table(name = "asset_assignments")
public class AssetAssignment {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID assignmentId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assetId", referencedColumnName = "assetId", foreignKey = @ForeignKey(name = "fk_assignment_asset"))
    @JsonIgnore
    private Asset asset;

    // ponytail: user XOR department — đúng 1 cái có giá trị. Đồ phòng ban: user null + department có
    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "userId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_assignment_user"))
    @JsonIgnore
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "departmentId", referencedColumnName = "departmentId", foreignKey = @ForeignKey(name = "fk_assignment_department"))
    @JsonIgnore
    private Department department;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assignedBy", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_assignment_assigner"))
    @JsonIgnore
    private User assignedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requestId", referencedColumnName = "requestId", foreignKey = @ForeignKey(name = "fk_assignment_request"))
    @JsonIgnore
    private AssetRequest request;

    @Column(name = "assigned_at", nullable = false)
    private LocalDateTime assignedAt;

    @Column(name = "expected_return_date")
    private LocalDate expectedReturnDate;

    @Column(name = "returned_at")
    private LocalDateTime returnedAt;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private AssignmentStatus status = AssignmentStatus.active;

    @Column(name = "condition_on_assign", columnDefinition = "TEXT")
    private String conditionOnAssign;

    @Column(name = "condition_on_return", columnDefinition = "TEXT")
    private String conditionOnReturn;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public UUID getAssetId() {
        return this.asset != null ? asset.getAssetId() : null;
    }

    public UUID getUserId() {
        return this.user != null ? user.getUserId() : null;
    }

    public UUID getDepartmentId() {
        return this.department != null ? department.getDepartmentId() : null;
    }

    // ponytail: scope để frontend chia 2 mục Của tôi / Của phòng — tính lúc đọc, khỏi cột mới
    public String getScope() {
        return this.department != null ? "DEPARTMENT" : "PERSONAL";
    }
}
