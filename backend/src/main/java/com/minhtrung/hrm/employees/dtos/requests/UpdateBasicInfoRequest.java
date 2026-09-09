package com.minhtrung.hrm.employees.dtos.requests;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO dành riêng cho việc cập nhật thông tin cơ bản ở Header / Trang chính.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateBasicInfoRequest {
    private String firstName;
    private String lastName;
    private String gender;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthDate;

    private String profilePicUrl;
    private String phoneNumber;
}
