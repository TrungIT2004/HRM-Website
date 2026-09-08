package com.minhtrung.social_app.employees.repositories;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.social_app.employees.entities.UserBankAccount;


public interface UserBankAccountRepository extends JpaRepository<UserBankAccount, UUID> {

}
