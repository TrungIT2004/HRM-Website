package com.minhtrung.hrm.resignation.dtos.responses;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.hrm.resignation.enums.ResignationStatus;

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
public class ResignationResponse {
    private UUID resignationId;

    // Thông tin người nộp
    private UUID userId;
    private String employeeCode;
    private String employeeName;
    private String departmentName;
    private String jobTitle;
    private String profilePicUrl;
    private LocalDate joinedDate;
    private String contractType;

    // Chi tiết đơn
    private LocalDateTime submittedTime;
    private LocalDate lastWorkingDate;
    private String reason;
    private ResignationStatus status;

    // Cấp 1: Phê duyệt bàn giao (Trưởng phòng)
    private UUID managerId;
    private String managerName;
    private String managerComment;
    private LocalDateTime managerApprovedAt;

    // Cấp 2: Phê duyệt chính thức (HR / Ban Giám Đốc)
    private UUID executiveId;
    private String executiveName;
    private String executiveComment;
    private LocalDateTime executiveApprovedAt;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
