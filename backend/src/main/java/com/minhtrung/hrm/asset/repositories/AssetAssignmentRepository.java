package com.minhtrung.hrm.asset.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.AssetAssignment;
import com.minhtrung.hrm.asset.enums.AssignmentStatus;

@Repository
public interface AssetAssignmentRepository extends JpaRepository<AssetAssignment, UUID> {
    List<AssetAssignment> findByAsset_AssetIdOrderByAssignedAtDesc(UUID assetId);

    List<AssetAssignment> findByUser_UserIdAndStatusOrderByAssignedAtDesc(UUID userId, AssignmentStatus status);

    List<AssetAssignment> findByDepartment_DepartmentIdAndStatusOrderByAssignedAtDesc(UUID departmentId, AssignmentStatus status);

    List<AssetAssignment> findByStatusOrderByAssignedAtDesc(AssignmentStatus status);

    List<AssetAssignment> findByStatusAndExpectedReturnDateBetween(AssignmentStatus status, LocalDate from, LocalDate to);

    boolean existsByUser_UserIdAndStatusIn(UUID userId, List<AssignmentStatus> statuses);
}
