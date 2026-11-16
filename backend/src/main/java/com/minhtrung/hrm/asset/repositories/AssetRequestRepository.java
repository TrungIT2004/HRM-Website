package com.minhtrung.hrm.asset.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.asset.entities.AssetRequest;
import com.minhtrung.hrm.asset.enums.AssetRequestStatus;

@Repository
public interface AssetRequestRepository extends JpaRepository<AssetRequest, UUID> {
    List<AssetRequest> findByRequestor_UserIdOrderByCreatedAtDesc(UUID userId);

    // ponytail: hàng chờ xử lý = pending (chờ duyệt) + approved (chờ pick mã để cấp)
    List<AssetRequest> findByStatusInOrderByCreatedAtDesc(List<AssetRequestStatus> statuses);

    List<AssetRequest> findByStatusInAndNeededByDateBetween(List<AssetRequestStatus> statuses, LocalDate from, LocalDate to);
}
