package com.minhtrung.hrm.auth.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.auth.entities.UserSession;


public interface UserSessionRepository extends JpaRepository<UserSession, UUID> {
    List<UserSession> findByUserId(UUID userId);
}
