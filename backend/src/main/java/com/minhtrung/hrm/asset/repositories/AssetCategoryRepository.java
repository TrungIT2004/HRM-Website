package com.minhtrung.hrm.asset.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.AssetCategory;

@Repository
public interface AssetCategoryRepository extends JpaRepository<AssetCategory, UUID> {
    Optional<AssetCategory> findByName(String name);

    Optional<AssetCategory> findByCodePrefix(String codePrefix);
}
