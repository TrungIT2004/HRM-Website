package com.minhtrung.social_app.employees.repositories;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.social_app.employees.entities.UserContract;


public interface UserContractRepository extends JpaRepository<UserContract, UUID> {

}
