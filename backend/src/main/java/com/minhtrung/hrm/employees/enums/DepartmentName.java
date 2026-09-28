package com.minhtrung.hrm.employees.enums;

import lombok.Getter;

/**
 * Danh sách 7 phòng ban chuẩn của hệ thống HRM và giá trị đặc biệt 'ALL' (toàn công ty).
 */
@Getter
public enum DepartmentName {
    ALL("ALL"),
    SALES("Sales"),
    MARKETING_COMMUNICATION("Marketing & Communication"),
    HUMAN_RESOURCES("Human Resources"),
    FINANCE_ACCOUNTING("Finance & Accounting"),
    CUSTOMER_SUPPORT("Customer Support"),
    EXECUTIVE_LEADERSHIP("Executive Leadership"),
    INFORMATION_TECHNOLOGY("Information Technology");

    private final String value;

    DepartmentName(String value) {
        this.value = value;
    }

    /**
     * Kiểm tra một chuỗi tên phòng ban có hợp lệ hay không (không phân biệt hoa thường).
     */
    public static boolean isValid(String name) {
        if (name == null || name.isBlank()) {
            return false;
        }
        String trimmed = name.trim();
        // ponytail: DB lưu tên ngắn "IT", enum dùng tên dài — chấp nhận cả hai
        if ("IT".equalsIgnoreCase(trimmed)) {
            return true;
        }
        for (DepartmentName d : values()) {
            if (d.value.equalsIgnoreCase(trimmed) || d.name().equalsIgnoreCase(trimmed)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Chuẩn hóa về tên phòng ban chính thức theo database.
     */
    public static String fromString(String name) {
        if (name == null || name.isBlank()) {
            return null;
        }
        String trimmed = name.trim();
        if ("IT".equalsIgnoreCase(trimmed)) {
            return INFORMATION_TECHNOLOGY.value;
        }
        for (DepartmentName d : values()) {
            if (d.value.equalsIgnoreCase(trimmed) || d.name().equalsIgnoreCase(trimmed)) {
                return d.value;
            }
        }
        return null;
    }
}
