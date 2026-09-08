package com.minhtrung.social_app.employees.dtos.requests;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
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
public class UpdateProfileRequest {

    // Thông tin cơ bản (users)
    private String firstName;
    private String lastName;
    private String gender;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthDate;

    private String profilePicUrl;

    // Thông tin định danh & pháp lý (user_profiles)
    private String phoneNumber;
    private String personalEmail;
    private String placeOfBirth;
    private String maritalStatus;
    private String nationality;
    private String citizenIdNumber;
    private String socialInsuranceNumber;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate socialInsuranceStartDate;

    private String taxIdentificationNumber;
    private String emergencyContactName;
    private String emergencyContactPhone;
}
