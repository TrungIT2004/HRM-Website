package com.minhtrung.hrm.admin.dtos.responses;

import java.time.LocalDate;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonFormat;

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
public class AdminAccountResponse {
    private UUID userId;
    private String employeeCode;
    private String fullName;
    private String email;
    private String departmentName;
    private String jobTitle;
    private Boolean isActive;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate joinedDate;

    private Integer activeSessionCount;
}
