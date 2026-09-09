package com.minhtrung.hrm.employees.repositories;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.employees.entities.UserProfile;

public interface UserProfileRepository extends JpaRepository<UserProfile, UUID> {

}
