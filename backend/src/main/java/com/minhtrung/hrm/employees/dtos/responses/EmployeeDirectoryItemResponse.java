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

    // Trạng thái hôm nay cho badge danh bạ.
    // todayStatus: truyền thẳng attendances.status; "DAY_OFF" = hôm nay không có bản ghi
    // (cron chỉ tạo record cho ngày làm việc — vắng record nghĩa là nghỉ).
    private String todayStatus;
    // "OVERTIMING" = đang tăng ca, "OVERTIME_DONE" = đã kết thúc tăng ca, null = không tăng ca.
    private String todayOvertimeStatus;
}
