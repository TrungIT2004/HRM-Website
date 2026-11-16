package com.minhtrung.hrm.asset.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.AssetImage;

@Repository
public interface AssetImageRepository extends JpaRepository<AssetImage, UUID> {
    List<AssetImage> findByAsset_AssetIdOrderByTakenAtDesc(UUID assetId);
}
