package com.minhtrung.hrm.overtime.dtos.responses;

import java.time.LocalDate;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Kết quả xem trước đơn tăng ca. Frontend hiển thị trực tiếp, không tự tính lại
 * hệ số để tránh lệch với bảng lương.
 *
 * @param endDate         ngày kết thúc nếu ca xuyên đêm sang ngày hôm sau, null nếu kết thúc cùng ngày
 * @param totalHours      tổng số giờ OT thực tế
 * @param isWeekend       ca rơi vào cuối tuần
 * @param isHoliday       có phủ ngày lễ hay không
 * @param isNightTime     có rơi vào khung giờ đêm (22:00 - 06:00) hay không
 * @param multiplier      hệ số tính lương (1.5 / 2.0 / 2.7 / 3.0 / 3.9)
 * @param paidHours       giờ tính tiền = totalHours * multiplier
 */
@Getter
@AllArgsConstructor
public class OvertimePreviewResponse {
    private final LocalDate endDate;
    private final double totalHours;
    private final boolean isWeekend;
    private final boolean isHoliday;
    private final boolean isNightTime;
    private final double multiplier;
    private final double paidHours;
}
