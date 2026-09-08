package com.minhtrung.social_app.employees.repositories;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.social_app.employees.entities.Department;


public interface DepartmentRepository extends JpaRepository<Department, UUID> {
    Optional<Department> findByName(String department);

    @Query("""
        SELECT d.departmentId
        FROM Department d 
        WHERE d.name = :departmentName 
    """)
    UUID getUsersDepartmentId(@Param("departmentName") String departmentName);
}
