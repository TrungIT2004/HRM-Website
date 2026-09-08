package com.minhtrung.social_app.overtime.enums;

public enum OvertimeErrorCode {

    // ─── Lỗi giới hạn thời gian ──────────────────────────
    EXCEED_MAXIMUM_OVERTIME,      // Tổng OT vượt 12h
    EXCEED_DAILY_TOTAL,           // Work + OT > 12
    EXCEED_50_PERCENT,            // OT > 50% workTime
    INSUFFICIENT_REST,            // Nghỉ giữa ca < 12h
    OVERLAP_WORK_HOURS,           // OT chồng lấn với giờ làm

    // ─── Lỗi về nhân viên ────────────────────────────────
    USER_NO_SHIFT,                // Không có ca làm việc
    SHIFT_NOT_FOUND,              // Không tìm thấy schedule

    // ─── Lỗi thời gian ────────────────────────────────────
    INVALID_TIME,                 // Thời gian không hợp lệ (start >= end, v.v.)
    INVALID_TIME_RANGE, // Range không hợp lệ (có thể dùng cùng INVALID_TIME)
    INSUFFICIENT_TIME,

    // ─── Lỗi giới hạn tháng/năm ──────────────────────────
    EXCEED_MONTHLY_OVERTIME,      // Vượt 40h/tháng
    EXCEED_YEARLY_OVERTIME,       // Vượt 200h/năm

    // ─── Lỗi về quyền và trạng thái ──────────────────────
    RECORD_NOT_FOUND,             // Không tìm thấy bản ghi
    NOT_RECORD_OWNER,             // Không phải chủ sở hữu
    INSUFFICIENT_PERMISSION,      // Không đủ quyền
    INVALID_STATUS, // Trạng thái không hợp lệ
    ALREADY_PROCESSED_REQUEST,
    CANNOT_CANCEL_NON_PENDING,

    // ─── Lỗi chung ────────────────────────────────────────
    GENERIC,                       // Lỗi không xác định
    INTERNAL_SERVER_ERROR,
    INSUFFICIENT_OT_TIME
}