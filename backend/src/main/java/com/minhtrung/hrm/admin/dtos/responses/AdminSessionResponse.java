package com.minhtrung.hrm.admin.dtos.responses;

import java.time.LocalDateTime;
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
public class AdminSessionResponse {
    private UUID sessionId;
    private UUID userId;
    private String employeeCode;
    private String userFullName;
    private String userEmail;
    private String departmentName;

    private String deviceType;
    private String deviceOS;
    private String browser;
    private String ipAddr;
    private String city;
    private String country;
    private String isp;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime lastActiveAt;

    private Boolean revoked;
}
