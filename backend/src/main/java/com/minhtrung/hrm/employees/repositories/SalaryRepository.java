package com.minhtrung.hrm.employees.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.employees.entities.Salary;

public interface SalaryRepository extends JpaRepository<Salary, UUID> {
    Optional<Salary> findByUser_UserId(UUID userId);
    Optional<Salary> findByUser_UserIdAndIsActiveTrue(UUID userId);
}
