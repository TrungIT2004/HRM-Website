package com.minhtrung.hrm.employees.dtos.requests;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO dành riêng cho việc cập nhật hồ sơ pháp lý & nhân thân ở Tab 1.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateLegalProfileRequest {
    private String citizenIdNumber;
    private String taxIdentificationNumber;
    private String socialInsuranceNumber;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate socialInsuranceStartDate;

    private String personalEmail;
    private String placeOfBirth;
    private String maritalStatus;
    private String nationality;
    private String emergencyContactName;
    private String emergencyContactPhone;
}
