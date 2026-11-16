package com.minhtrung.hrm.employees.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.employees.entities.UserBankAccount;


public interface UserBankAccountRepository extends JpaRepository<UserBankAccount, UUID> {

    List<UserBankAccount> findByUser_UserIdOrderByIsDefaultDesc(UUID userId);

    // Tài khoản nhận lương. Ponytail: DB có partial unique index nên tối đa 1 dòng.
    Optional<UserBankAccount> findFirstByUser_UserIdAndIsDefaultTrue(UUID userId);
}
