package com.minhtrung.hrm.permissions.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.permissions.entities.PermissionGrant;
import com.minhtrung.hrm.permissions.entities.PermissionGrant.PermissionGrantId;
import com.minhtrung.hrm.permissions.enums.PermissionKey;

@Repository
public interface PermissionGrantRepository extends JpaRepository<PermissionGrant, PermissionGrantId> {

    List<PermissionGrant> findByUserId(UUID userId);

    boolean existsByUserIdAndPermission(UUID userId, PermissionKey permission);

    void deleteByUserId(UUID userId);
}
