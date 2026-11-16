package com.minhtrung.hrm.admin.dtos.requests;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreatePendingUserRequest {

    @NotBlank(message = "Họ không được để trống")
    private String firstName;

    @NotBlank(message = "Tên không được để trống")
    private String lastName;

    @NotBlank(message = "Giới tính không được để trống")
    private String gender;

    @NotNull(message = "Ngày sinh không được để trống")
    private LocalDate birthDate;

    @NotBlank(message = "Email cá nhân không được để trống")
    @Email(message = "Email cá nhân không hợp lệ")
    private String personalEmail;

    private String phoneNumber;
    private String citizenId;
    private String placeOfBirth;

    @NotNull(message = "Phòng ban không được để trống")
    private UUID departmentId;

    @NotNull(message = "Chức danh không được để trống")
    private UUID jobId;

    private UUID shiftId;
    private BigDecimal baseSalary;
    private String contractType;
    private LocalDate contractStartDate;
    private LocalDate contractEndDate;
}
