package com.minhtrung.hrm.employees.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.employees.entities.UserContract;

@Repository
public interface UserContractRepository extends JpaRepository<UserContract, UUID> {
    Optional<UserContract> findByUser_UserId(UUID userId);

    @Query("SELECT c FROM UserContract c WHERE c.user.userId = :userId")
    Optional<UserContract> findByUserId(@Param("userId") UUID userId);
}
