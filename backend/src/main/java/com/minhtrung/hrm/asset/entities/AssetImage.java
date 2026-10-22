package com.minhtrung.hrm.asset.entities;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.minhtrung.hrm.employees.entities.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "asset_images")
public class AssetImage {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID imageId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assetId", referencedColumnName = "assetId", foreignKey = @ForeignKey(name = "fk_image_asset"))
    @JsonIgnore
    private Asset asset;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignmentId", referencedColumnName = "assignmentId", foreignKey = @ForeignKey(name = "fk_image_assignment"))
    @JsonIgnore
    private AssetAssignment assignment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "maintenanceId", referencedColumnName = "maintenanceId", foreignKey = @ForeignKey(name = "fk_image_maintenance"))
    @JsonIgnore
    private AssetMaintenance maintenance;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventoryLogId", referencedColumnName = "logId", foreignKey = @ForeignKey(name = "fk_image_inventory"))
    @JsonIgnore
    private AssetInventoryLog inventoryLog;

    @NotBlank(message = "Đường dẫn ảnh không được để trống")
    @Column(name = "image_url", nullable = false)
    private String imageUrl;

    @Column
    private String caption;

    @Column(name = "is_cover", nullable = false)
    private boolean cover = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "takenBy", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_image_taker"))
    @JsonIgnore
    private User takenBy;

    @CreationTimestamp
    @Column(name = "taken_at", nullable = false, updatable = false)
    private LocalDateTime takenAt;

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

    @JsonProperty("assignmentId")
    public void setAssignmentId(UUID assignmentId) {
        if (assignmentId != null) {
            AssetAssignment stub = new AssetAssignment();
            stub.setAssignmentId(assignmentId);
            this.assignment = stub;
        }
    }

    @JsonProperty("maintenanceId")
    public void setMaintenanceId(UUID maintenanceId) {
        if (maintenanceId != null) {
            AssetMaintenance stub = new AssetMaintenance();
            stub.setMaintenanceId(maintenanceId);
            this.maintenance = stub;
        }
    }

    @JsonProperty("inventoryLogId")
    public void setInventoryLogId(UUID inventoryLogId) {
        if (inventoryLogId != null) {
            AssetInventoryLog stub = new AssetInventoryLog();
            stub.setLogId(inventoryLogId);
            this.inventoryLog = stub;
        }
    }
}
