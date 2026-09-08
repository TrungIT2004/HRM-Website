package com.minhtrung.social_app.employees.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.social_app.employees.entities.Job;

public interface JobRepository extends JpaRepository<Job, UUID> {
    Optional<Job> findByTitle(String job);
}
