package com.minhtrung.hrm.employees.dtos.requests;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO dành cho HR tạo mới một tài khoản và hồ sơ nhân viên trọn gói.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateEmployeeRequest {

    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String email;

    @NotBlank(message = "Mật khẩu ban đầu không được để trống")
    @Size(min = 8, message = "Mật khẩu khởi tạo phải có tối thiểu 8 ký tự")
    private String password;

    @NotBlank(message = "Họ và tên đệm (firstName) không được để trống")
    private String firstName;

    @NotBlank(message = "Tên (lastName) không được để trống")
    private String lastName;

    private String gender;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate joinedDate;

    @NotNull(message = "Phòng ban (departmentId) không được để trống")
    private UUID departmentId;

    @NotNull(message = "Chức vụ (jobId) không được để trống")
    private UUID jobId;

    @NotNull(message = "Ca làm việc (shiftId) không được để trống")
    private UUID shiftId;

    private String employeeCode;

    private String phoneNumber;

    private String citizenId;

    private String address;

    @NotNull(message = "Mức lương cơ bản (baseSalary) không được để trống")
    private BigDecimal baseSalary;

    private String profilePicUrl;
}
