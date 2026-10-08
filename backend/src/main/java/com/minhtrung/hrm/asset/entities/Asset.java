package com.minhtrung.hrm.asset.entities;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.minhtrung.hrm.asset.enums.AssetStatus;
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
import jakarta.persistence.Transient;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "assets")
public class Asset {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID assetId;

    @Column(name = "asset_code", nullable = false, unique = true, length = 20)
    private String assetCode;

    @NotBlank(message = "Tên tài sản không được để trống")
    @Column(nullable = false)
    private String name;

    @NotNull(message = "Loại tài sản không được để trống")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "categoryId", referencedColumnName = "categoryId", foreignKey = @ForeignKey(name = "fk_asset_category"))
    @JsonIgnore
    private AssetCategory category;

    @Column(name = "serial_number", unique = true)
    private String serialNumber;

    @Column(columnDefinition = "TEXT")
    private String specs;

    @Column(name = "purchase_date")
    private LocalDate purchaseDate;

    @Column(name = "purchase_cost")
    private Double purchaseCost;

    @Column
    private String supplier;

    @Column(name = "useful_life_months", nullable = false)
    private int usefulLifeMonths = 36;

    @Column(name = "warranty_until")
    private LocalDate warrantyUntil;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private AssetStatus status = AssetStatus.available;

    @Column(name = "condition_note", columnDefinition = "TEXT")
    private String conditionNote;

    @Column(columnDefinition = "TEXT")
    private String location;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currentHolderId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_asset_holder"))
    @JsonIgnore
    private User currentHolder;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "createdBy", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_asset_creator"))
    @JsonIgnore
    private User createdBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public UUID getCategoryId() {
        return this.category != null ? category.getCategoryId() : null;
    }

    // ponytail: trả entity trực tiếp thay vì DTO nên cần setter write-only cho FK —
    // service sẽ thay bằng managed entity ngay sau đó, proxy này không bao giờ persist
    @JsonProperty("categoryId")
    public void setCategoryId(UUID categoryId) {
        if (categoryId != null) {
            AssetCategory stub = new AssetCategory();
            stub.setCategoryId(categoryId);
            this.category = stub;
        }
    }

    public UUID getCurrentHolderId() {
        return this.currentHolder != null ? currentHolder.getUserId() : null;
    }

    // ponytail: khấu hao đường thẳng tính lúc đọc thay vì bảng lịch sử — đủ cho V1, tách bảng khi kế toán cần chốt sổ tháng
    @Transient
    @JsonIgnore
    public Double getRemainingValue() {
        if (purchaseCost == null || purchaseDate == null || usefulLifeMonths <= 0) return purchaseCost;
        long used = ChronoUnit.MONTHS.between(purchaseDate.withDayOfMonth(1), LocalDate.now().withDayOfMonth(1));
        if (used < 0) used = 0;
        if (used >= usefulLifeMonths) return 0.0;
        return purchaseCost * (usefulLifeMonths - used) / usefulLifeMonths;
    }
}
