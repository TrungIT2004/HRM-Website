package com.minhtrung.hrm.asset.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.AssetInventoryLog;

@Repository
public interface AssetInventoryLogRepository extends JpaRepository<AssetInventoryLog, UUID> {
    List<AssetInventoryLog> findByAsset_AssetIdOrderByCheckedAtDesc(UUID assetId);
}
