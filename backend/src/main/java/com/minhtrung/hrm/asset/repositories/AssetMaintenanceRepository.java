package com.minhtrung.hrm.asset.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.AssetMaintenance;

@Repository
public interface AssetMaintenanceRepository extends JpaRepository<AssetMaintenance, UUID> {
    List<AssetMaintenance> findByAsset_AssetIdOrderBySentAtDesc(UUID assetId);
}
