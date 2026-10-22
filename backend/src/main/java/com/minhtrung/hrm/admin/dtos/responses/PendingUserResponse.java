package com.minhtrung.hrm.admin.dtos.responses;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
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
public class PendingUserResponse {
    private UUID pendingId;
    private String firstName;
    private String lastName;
    private String fullName;
    private String gender;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthDate;

    private String personalEmail;
    private String phoneNumber;
    private String citizenId;
    private String placeOfBirth;

    private UUID departmentId;
    private String departmentName;

    private UUID jobId;
    private String jobTitle;

    private UUID shiftId;
    private String shiftName;

    private BigDecimal baseSalary;
    private String contractType;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate contractStartDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate contractEndDate;

    private String status;
    private String rejectionReason;
    private String createdByName;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private OffsetDateTime createdAt;
}
