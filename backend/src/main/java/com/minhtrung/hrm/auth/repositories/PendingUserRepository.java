package com.minhtrung.hrm.auth.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.auth.entities.PendingUser;

@Repository
public interface PendingUserRepository extends JpaRepository<PendingUser, UUID> {
    List<PendingUser> findByStatusOrderByCreatedAtDesc(String status);

    boolean existsByPersonalEmail(String personalEmail);

    Optional<PendingUser> findByPersonalEmail(String personalEmail);
}
