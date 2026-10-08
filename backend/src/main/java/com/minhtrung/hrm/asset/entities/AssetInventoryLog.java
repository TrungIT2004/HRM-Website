package com.minhtrung.hrm.asset.entities;

import java.time.LocalDateTime;
import java.util.UUID;

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
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "asset_inventory_logs")
public class AssetInventoryLog {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID logId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assetId", referencedColumnName = "assetId", foreignKey = @ForeignKey(name = "fk_inventory_asset"))
    @JsonIgnore
    private Asset asset;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "checkedBy", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_inventory_checker"))
    @JsonIgnore
    private User checkedBy;

    @Column(name = "checked_at", nullable = false)
    private LocalDateTime checkedAt;

    @Column(nullable = false)
    private boolean found = true;

    @Column(name = "condition_note", columnDefinition = "TEXT")
    private String conditionNote;

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
