package com.minhtrung.social_app.auth.dtos.requests;

import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class SignUpRequest {
    @NotNull(message = "Phòng ban (departmentId) không được để trống")
    private UUID departmentId; 

    @NotNull(message = "Chức vụ (jobId) không được để trống")
    private UUID jobId;

    private String employeeCode;

    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String email;

    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 6, message = "Mật khẩu phải có tối thiểu 6 ký tự")
    private String password;

    @NotBlank(message = "Họ/Tên đệm (firstName) không được để trống")
    private String firstName; 

    @NotBlank(message = "Tên (lastName) không được để trống")
    private String lastName; 

    private String profilePicUrl; 
    private String gender;
    private LocalDate birthDate; 
    private LocalDate joinedDate;
    private int annualLeaveDays; 
    private int usedLeaveDays;
}