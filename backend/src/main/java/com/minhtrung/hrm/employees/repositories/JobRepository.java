package com.minhtrung.hrm.employees.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.employees.entities.Job;

public interface JobRepository extends JpaRepository<Job, UUID> {
    Optional<Job> findByTitle(String job);
    List<Job> findByDepartment_DepartmentId(UUID departmentId);
    boolean existsByTitleAndDepartment_DepartmentId(String title, UUID departmentId);

    /** Đếm chức danh thuộc phòng ban — chặn xoá phòng ban khi còn chức danh. */
    int countByDepartment_DepartmentId(UUID departmentId);
}
