package com.minhtrung.hrm.employees.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.employees.entities.UserContract;

@Repository
public interface UserContractRepository extends JpaRepository<UserContract, UUID> {
    
    @Query("SELECT c FROM UserContract c WHERE c.user.userId = :userId AND c.isActive = true")
    Optional<UserContract> findByUser_UserId(@Param("userId") UUID userId);

    @Query("SELECT c FROM UserContract c WHERE c.user.userId = :userId AND c.isActive = true")
    Optional<UserContract> findByUserId(@Param("userId") UUID userId);

    List<UserContract> findByUser_UserIdAndIsActiveTrue(UUID userId);

    Optional<UserContract> findFirstByUser_UserIdAndIsActiveTrueOrderByContractStartDateDesc(UUID userId);

    List<UserContract> findByUser_UserIdOrderByContractStartDateDesc(UUID userId);

    List<UserContract> findByUser_UserIdAndIsActiveTrueOrderByContractStartDateDesc(UUID userId);
}
