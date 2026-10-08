package com.minhtrung.hrm.permissions.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Danh mục quyền cấp thêm cho từng nhân sự (Admin tick trong trang /admin).
 * Quyền hiệu lực = quyền gốc theo phòng ban/chức danh OR grant.
 * Untick grant không bao giờ tước quyền gốc.
 */
@Getter
@RequiredArgsConstructor
public enum PermissionKey {
    ATTENDANCE_VIEW_ALL("Xem chấm công toàn công ty"),
    LEAVE_VIEW_ALL("Xem nghỉ phép toàn công ty"),
    OVERTIME_VIEW_ALL("Xem tăng ca toàn công ty"),
    PAYROLL_VIEW_ALL("Xem lương toàn công ty"),
    RESIGN_VIEW_ALL("Xem thôi việc toàn công ty"),
    LEAVE_APPROVE("Duyệt / từ chối đơn nghỉ phép"),
    OVERTIME_APPROVE("Duyệt / từ chối đơn tăng ca"),
    RESIGN_APPROVE("Duyệt đơn thôi việc"),
    TIMESHEET_LOCK("Tính toán + chốt sổ bảng công"),
    PAYROLL_MANAGE("Tính + duyệt bảng lương"),
    // ─── Quyền phạm vi phòng ban (chỉ thấy/duyệt dữ liệu phòng mình, cấp cho Trưởng phòng) ───
    ATTENDANCE_VIEW_DEPT("Xem chấm công phòng ban"),
    LEAVE_VIEW_DEPT("Xem nghỉ phép phòng ban"),
    OVERTIME_VIEW_DEPT("Xem tăng ca phòng ban"),
    LEAVE_APPROVE_DEPT("Duyệt / từ chối đơn nghỉ phép phòng ban"),
    OVERTIME_APPROVE_DEPT("Duyệt / từ chối đơn tăng ca phòng ban"),
    // ─── Quyền đánh giá hiệu suất (Form 6, 10 tiêu chí 1-5) ───
    EVALUATION_VIEW_ALL("Xem đánh giá hiệu suất toàn công ty"),
    EVALUATION_VIEW_DEPT("Xem đánh giá hiệu suất phòng ban"),
    EVALUATION_APPROVE("Chấm + khóa sổ đánh giá toàn công ty"),
    EVALUATION_APPROVE_DEPT("Chấm đánh giá hiệu suất phòng ban"),

    // ─── Quyền quản trị hệ thống (mặc định: System Administrator, trừ ORG_MANAGE = HR) ───
    // Quyền gốc: isSysAdmin. Gỡ isExecutive — Ban Giám Đốc không phải quản trị viên hệ thống.
    ACCOUNT_LOCK("Mở / khóa tài khoản nhân viên"),
    // Quyền gốc: isSysAdmin. Tách khỏi ACCOUNT_LOCK vì đây là meta-permission (cấp quyền cho người khác).
    PERMISSION_GRANT("Cấp quyền cho nhân viên khác"),
    // Quyền gốc: phòng Human Resources. Gộp cả xem — master data không nhạy cảm và GET hiện không chặn ai.
    ORG_MANAGE("Quản lý phòng ban, chức danh & ca làm việc"),
    // Tách khỏi EMPLOYEE_EDIT vì dữ liệu nhạy cảm (lương, CCCD, hợp đồng) — có thể cấp chỉ-để-xem.
    EMPLOYEE_VIEW_ALL("Xem hồ sơ nhân viên toàn công ty"),
    // Quyền gốc: phòng Human Resources.
    EMPLOYEE_EDIT("Chỉnh sửa hồ sơ nhân viên"),
    // Quyền gốc: Executive / SysAdmin / HR / Trưởng phòng (xem AiController). Grant thêm cho nhân viên thường.
    DOCUMENT_UPLOAD("Đăng tải tài liệu & quy chế"),
    // ─── Quyền tài sản (không hardcode dept/job — chỉ check bảng grants, SUPER_ADMIN bypass) ───
    VIEW_ASSETS("Xem tài sản toàn công ty"),
    MANAGE_ASSETS("Nhập / cấp / thu hồi tài sản"),
    // ─── Quyền IT ticket — chỉ người được cấp mới thấy hàng chờ / nhận / xử lý ───
    IT_TICKET_HANDLE("Nhận và xử lý IT ticket");

    private final String label;
}
