package com.minhtrung.hrm.asset.entities;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.minhtrung.hrm.asset.enums.MaintenanceStatus;
import com.minhtrung.hrm.asset.enums.MaintenanceType;
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
@Table(name = "asset_maintenances")
public class AssetMaintenance {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID maintenanceId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assetId", referencedColumnName = "assetId", foreignKey = @ForeignKey(name = "fk_maintenance_asset"))
    @JsonIgnore
    private Asset asset;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reportedBy", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_maintenance_reporter"))
    @JsonIgnore
    private User reportedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "handledBy", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_maintenance_handler"))
    @JsonIgnore
    private User handledBy;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private MaintenanceType type;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private MaintenanceStatus status = MaintenanceStatus.reported;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column
    private Double cost;

    @Column
    private String vendor;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "returned_at")
    private LocalDateTime returnedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public UUID getAssetId() {
        return this.asset != null ? asset.getAssetId() : null;
    }

    // ponytail: setter write-only cho FK (trả entity trực tiếp thay vì DTO) — xem Asset.setCategoryId
    @JsonProperty("assetId")
    public void setAssetId(UUID assetId) {
        if (assetId != null) {
            Asset stub = new Asset();
            stub.setAssetId(assetId);
            this.asset = stub;
        }
    }
}
