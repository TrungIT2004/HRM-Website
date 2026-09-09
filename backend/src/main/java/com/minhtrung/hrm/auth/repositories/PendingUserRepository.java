package com.minhtrung.hrm.auth.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.auth.entities.PendingUser;


public interface PendingUserRepository extends JpaRepository<PendingUser, UUID> {
    Optional<PendingUser> findByEmail(String email);

    boolean existsByEmail(String email);
    void deleteByEmail(String email);
}
