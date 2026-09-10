package com.minhtrung.hrm.employees.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.auth.dtos.internals.UserAuthInfo;
import com.minhtrung.hrm.employees.dtos.internals.UserDetailedInfo;
import com.minhtrung.hrm.employees.entities.User;

public interface UserRepository extends JpaRepository<User, UUID> {
    @Query(value = "SELECT nextval('employee_number_seq')", nativeQuery = true)
    Long getNextEmployeeNumber();
    
    boolean existsByEmail(String email);
    int countByDepartment_DepartmentId(UUID departmentId);

    @Query("SELECT u FROM User u WHERE u.email = :email")
    User findByEmail(String email);

    @Query("SELECT u.userId FROM User u WHERE u.job.title LIKE 'Department Head of%'")
    List<UUID> getDepartmentHeadIds();

    @Query("SELECT s FROM User u JOIN u.shift s WHERE u.userId = :userId")
    Optional<WorkShift> getUsersWorkShift(@Param("userId") UUID userId);

    @Query("""
        SELECT d.name
        FROM User u
        JOIN u.department d      
        WHERE u.userId = :userId  
    """)
    String findUsersDepartment(@Param("userId") UUID userId);

    @Query("""
        SELECT j.title
        FROM User u
        JOIN u.job j
        WHERE u.userId = :userId  
    """)
    String findUsersJob(@Param("userId") UUID userId);
    

    @Query("""
        SELECT new com.minhtrung.hrm.auth.dtos.internals.UserAuthInfo(u.userId, u.email, u.password, CONCAT(u.firstName, ' ', u.lastName), u.profilePicUrl, d.name, j.title, u.isActive)
        FROM User u
        JOIN u.department d
        JOIN u.job j
        WHERE u.email = :email      
    """)
    UserAuthInfo getUserInfo(@Param("email") String email);

    @Query("SELECT new com.minhtrung.hrm.employees.dtos.internals.UserDetailedInfo(" +
       "u.userId, u.email, u.firstName, u.lastName, u.gender, u.birthDate, u.joinedDate, u.profilePicUrl, u.annualLeaveDays, u.usedLeaveDays, " +
       "d.name, j.title, s.baseSalary," +
       "p.phoneNumber, p.personalEmail, p.placeOfBirth, p.maritalStatus, p.nationality, p.citizenIdNumber, p.socialInsuranceNumber, p.taxIdentificationNumber, p.socialInsuranceStartDate, p.emergencyContactName, p.emergencyContactPhone, " +
       "b.bankName, b.bankAccountNumber, " +
       "c.contractType, c.contractStartDate, c.contractEndDate) " +
       "FROM User u " +
       "LEFT JOIN u.department d " +
       "LEFT JOIN u.job j " +
       "LEFT JOIN u.salaries s " +
       "LEFT JOIN u.profile p " +
       "LEFT JOIN u.bankAccount b " +
       "LEFT JOIN u.contract c " + 
       "WHERE u.userId = :userId")
    UserDetailedInfo getUsersDetailedInfo(@Param("userId") UUID userId);

    @Query("SELECT new com.minhtrung.hrm.employees.dtos.internals.UserDetailedInfo(" +
       "u.userId, u.email, u.firstName, u.lastName, u.gender, u.birthDate, u.joinedDate, u.profilePicUrl, u.annualLeaveDays, u.usedLeaveDays, " +
       "d.name, j.title, s.baseSalary," +
       "p.phoneNumber, p.personalEmail, p.placeOfBirth, p.maritalStatus, p.nationality, p.citizenIdNumber, p.socialInsuranceNumber, p.taxIdentificationNumber, p.socialInsuranceStartDate, p.emergencyContactName, p.emergencyContactPhone, " +
       "b.bankName, b.bankAccountNumber, " +
       "c.contractType, c.contractStartDate, c.contractEndDate) " +
       "FROM User u " +
       "LEFT JOIN u.department d " +
       "LEFT JOIN u.job j " +
       "LEFT JOIN u.salaries s " +
       "LEFT JOIN u.profile p " +
       "LEFT JOIN u.bankAccount b " +
       "LEFT JOIN u.contract c")
    List<UserDetailedInfo> getAllUsersDetailedInfo();

    @Query("""
        SELECT u FROM User u
        WHERE (:department IS NULL OR :department = '' OR u.department.name = :department)
          AND (:keyword IS NULL OR :keyword = '' OR 
               LOWER(u.employeeCode) LIKE LOWER(CONCAT('%', :keyword, '%')) OR 
               LOWER(CONCAT(u.firstName, ' ', u.lastName)) LIKE LOWER(CONCAT('%', :keyword, '%')) OR 
               LOWER(u.email) LIKE LOWER(CONCAT('%', :keyword, '%')))
    """)
    Page<User> findUsersByDepartmentAndKeyword(
        @Param("department") String department,
        @Param("keyword") String keyword,
        Pageable pageable
    );

    @Query("""
        SELECT u FROM User u
        WHERE (:department IS NULL OR :department = '' OR u.department.name = :department)
          AND (:keyword IS NULL OR :keyword = '' OR 
               LOWER(u.employeeCode) LIKE LOWER(CONCAT('%', :keyword, '%')) OR 
               LOWER(CONCAT(u.firstName, ' ', u.lastName)) LIKE LOWER(CONCAT('%', :keyword, '%')) OR 
               LOWER(u.email) LIKE LOWER(CONCAT('%', :keyword, '%')))
        ORDER BY u.department.name ASC, u.employeeCode ASC
    """)
    List<User> findUsersByDepartmentAndKeywordList(
        @Param("department") String department,
        @Param("keyword") String keyword
    );
}
