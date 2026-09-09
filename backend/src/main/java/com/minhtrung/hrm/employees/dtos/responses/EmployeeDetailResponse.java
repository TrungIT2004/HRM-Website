package com.minhtrung.hrm.employees.dtos.responses;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * DTO trọn gói trả về toàn bộ thông tin chi tiết của nhân viên.
 * Bao gồm thông tin công khai và 3 Tab riêng tư:
 * - publicProfile: Trang chính công khai (users, jobs, departments, schedules, today attendance)
 * - legalProfile: Tab 1 - Định danh & Pháp lý (user_profiles)
 * - contract: Tab 2 - Hợp đồng lao động (user_contracts)
 * - payroll: Tab 3 - Lương & Ngân hàng (salaries & user_bank_accounts)
 * 
 * Lưu ý: Tùy theo vai trò của người gọi API, Backend sẽ tự động gán null các trường/khối không có quyền xem!
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeDetailResponse {

    // 1. Khối thông tin công khai (Trang chính)
    private EmployeePublicProfile publicProfile;

    // 2. Tab 1: Định danh & Pháp lý (Chỉ Me + HR/Giám đốc xem được)
    private LegalProfileDto legalProfile;

    // 3. Tab 2: Hợp đồng lao động (Me + Trưởng phòng cùng team + HR/Giám đốc)
    private ContractDto contract;

    // 4. Tab 3: Lương & Ngân hàng (Chỉ Me + HR/Giám đốc xem được)
    private PayrollDto payroll;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LegalProfileDto {
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

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ContractDto {
        private String contractType;

        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate contractStartDate;

        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate contractEndDate;

        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate probationEndDate;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PayrollDto {
        private Long baseSalary;
        private String payFrequency;
        private Double workDays;

        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate startDate;

        @JsonFormat(pattern = "yyyy-MM-dd")
        private LocalDate endDate;

        private Boolean isActive;
        private String bankName;
        private String bankAccountNumber;
    }
}
