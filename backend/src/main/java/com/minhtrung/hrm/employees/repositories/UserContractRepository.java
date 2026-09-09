package com.minhtrung.hrm.employees.repositories;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.employees.entities.UserContract;


public interface UserContractRepository extends JpaRepository<UserContract, UUID> {

}
