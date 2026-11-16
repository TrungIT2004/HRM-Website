package com.minhtrung.hrm.asset.entities;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.minhtrung.hrm.asset.enums.AssetRequestStatus;
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
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "asset_requests")
public class AssetRequest {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID requestId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requestorId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_asset_request_user"))
    @JsonIgnore
    private User requestor;

    @NotNull(message = "Loại tài sản không được để trống")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "categoryId", referencedColumnName = "categoryId", foreignKey = @ForeignKey(name = "fk_asset_request_category"))
    @JsonIgnore
    private AssetCategory category;

    @NotBlank(message = "Lý do không được để trống")
    @Column(nullable = false, columnDefinition = "TEXT")
    private String reason;

    @Column(name = "needed_by_date")
    private LocalDate neededByDate;

    @Column(name = "expected_return_date")
    private LocalDate expectedReturnDate;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private AssetRequestStatus status = AssetRequestStatus.pending;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approverId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_asset_request_approver"))
    @JsonIgnore
    private User approver;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

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

    public UUID getCategoryId() {
        return this.category != null ? category.getCategoryId() : null;
    }

    // ponytail: setter write-only cho FK (trả entity trực tiếp thay vì DTO) — xem Asset.setCategoryId
    @JsonProperty("categoryId")
    public void setCategoryId(UUID categoryId) {
        if (categoryId != null) {
            AssetCategory stub = new AssetCategory();
            stub.setCategoryId(categoryId);
            this.category = stub;
        }
    }
}
