package com.minhtrung.social_app.attendance.dtos.requests;

import java.math.BigDecimal;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class MonthlyTimesheetEditRequest {
    private BigDecimal actualWorkedDays;
    private BigDecimal actualWorkHours;
    private BigDecimal totalActualOtHours;
    private BigDecimal totalPaidOtHours;
    private BigDecimal paidLeaveDays;
    private BigDecimal unpaidLeaveDays;
    private Integer lateCount;
    private Integer totalLateMinutes;
    private Integer earlyDepartureCount;
    private BigDecimal absentDays;

    @Size(max = 500, message = "Ghi chú lý do chỉnh sửa không được vượt quá 500 ký tự")
    private String note;
}
