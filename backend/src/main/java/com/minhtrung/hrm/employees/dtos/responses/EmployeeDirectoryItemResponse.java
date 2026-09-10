package com.minhtrung.hrm.employees.dtos.responses;

import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO siêu tinh gọn trả về cho danh bạ nhân viên (Trang danh sách tìm kiếm).
 * Chỉ gồm đúng 6 trường nhận diện tối thiểu.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeDirectoryItemResponse {
    private UUID userId;
    private String employeeCode;
    private String fullName;
    private String profilePicUrl;
    private String departmentName;
    private String jobTitle;
    private boolean isActive;
}
