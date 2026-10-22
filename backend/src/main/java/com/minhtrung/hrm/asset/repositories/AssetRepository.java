package com.minhtrung.hrm.asset.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.Asset;
import com.minhtrung.hrm.asset.enums.AssetStatus;

@Repository
public interface AssetRepository extends JpaRepository<Asset, UUID> {
    Optional<Asset> findByAssetCode(String assetCode);

    long countByCategory_CategoryId(UUID categoryId);

    List<Asset> findByStatus(AssetStatus status);

    List<Asset> findByCurrentHolder_UserIdAndStatus(UUID userId, AssetStatus status);
}
