package com.minhtrung.hrm.employees.entities;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.leave.entities.LeaveRequest;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID userId;

    @Column(nullable = false, unique = true)
    private String email;

    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 8, message = "Mật khẩu phải có tối thiểu 8 ký tự")
    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @Column(nullable = false)
    private String gender;

    @Column(nullable = false)
    private LocalDate birthDate;

    @Column(nullable = false)
    private String profilePicUrl;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDate joinedDate;

    @Column(nullable = false)
    private int annualLeaveDays = 12;

    @Column(nullable = false)
    private int usedLeaveDays = 0;

    @Column(name = "employee_code", nullable = false, unique = true, length = 10)
    private String employeeCode;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "departmentId", referencedColumnName = "departmentId", foreignKey = @ForeignKey(name = "fk_user_department"))
    @JsonIgnore
    private Department department;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "jobId", referencedColumnName = "jobId", foreignKey = @ForeignKey(name = "fk_user_job"))
    @JsonIgnore
    private Job job;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "shiftId", referencedColumnName = "shiftId", foreignKey = @ForeignKey(name = "fk_user_shift"))
    @JsonIgnore
    private WorkShift shift;

    @OneToMany(fetch = FetchType.LAZY, mappedBy = "user", orphanRemoval = true, cascade = CascadeType.ALL)
    @JsonIgnore
    private List<Salary> salaries;

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY, orphanRemoval = true, cascade = CascadeType.ALL)
    @JsonIgnore
    private List<Attendance> attendanceList;

    @OneToMany(mappedBy = "requestor", fetch = FetchType.LAZY, orphanRemoval = true, cascade = CascadeType.ALL)
    @JsonIgnore
    private List<LeaveRequest> leaveRequestList;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY, optional = true)
    private UserProfile profile;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY, optional = true)
    private UserBankAccount bankAccount;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY, optional = true)
    private UserContract contract;

}