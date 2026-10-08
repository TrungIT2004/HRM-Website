"""Allowlist schema cho Text-to-SQL. LLM chỉ thấy những gì trong file này.

Quy ước mỗi bảng:
- user_col: cột gắn user để ép phạm vi (None = bảng tra cứu dùng chung).
- columns: cột LLM được SELECT (khớp với GRANT trong sql/readonly_role.sql).
- note: ghi chú tiếng Việt giúp LLM viết SQL đúng ngay lần đầu.
"""
from typing import Dict, List, Optional

TABLES: Dict[str, Dict] = {
    "users": {
        "user_col": "user_id",
        "columns": ["user_id", "email", "first_name", "last_name", "gender",
                    "birth_date", "joined_date", "annual_leave_days",
                    "used_leave_days", "employee_code", "department_id",
                    "job_id", "shift_id", "is_active"],
        "note": "Ngày phép còn lại = annual_leave_days - used_leave_days. "
                "Không có cột password/face_embedding ở đây.",
    },
    "attendances": {
        "user_col": "user_id",
        "columns": ["attendance_id", "user_id", "work_date", "clock_in_time",
                    "clock_out_time", "status", "shift_id", "is_edited",
                    "edited_reason", "is_deleted"],
        "note": "clock_in/out là kiểu TIME, work_date là DATE. "
                "Giờ làm 1 ngày = EXTRACT(EPOCH FROM (clock_out_time - clock_in_time))/3600. "
                "Bỏ qua dòng is_deleted = TRUE. "
                "status: NOT_CHECKED/WORKING/SUFFICIENT/LATE/EARLY/LATE_AND_EARLY/"
                "MISSING/UNEXCUSED_ABSENCE/PAID_LEAVE/UNPAID_LEAVE/HOLIDAY/"
                "BUSINESS_TRIP/ADJUSTED.",
    },
    "monthly_timesheets": {
        "user_col": "user_id",
        "columns": ["timesheet_id", "user_id", "period_month", "period_year",
                    "standard_working_days", "actual_worked_days",
                    "actual_work_hours", "late_count", "total_late_minutes",
                    "early_departure_count", "absent_days", "paid_leave_days",
                    "unpaid_leave_days", "total_actual_ot_hours",
                    "total_paid_ot_hours", "status", "note"],
        "note": "Bảng tổng hợp sẵn theo tháng. Hỏi tổng giờ/ngày làm theo "
                "tháng/năm thì đọc bảng này TRƯỚC, chỉ SUM attendances khi "
                "cần chi tiết từng ngày.",
    },
    "leave_requests": {
        "user_col": "requestor_id",
        "columns": ["request_id", "requestor_id", "from_date", "to_date",
                    "paid_leave_days", "reason", "status", "approver_id",
                    "rejection_reason", "created_at", "updated_at"],
        "note": "Cột gắn user là requestor_id (không phải user_id). "
                "status CHỮ THƯỜNG: 'pending' / 'accepted' / 'rejected'. "
                "Đơn được duyệt là 'accepted'. from_date..to_date là khoảng, "
                "tính số ngày = to_date - from_date + 1. Đây là đơn NGHỈ PHÉP "
                "(xin nghỉ) — phân biệt với resignation_requests (xin NGHỈ VIỆC).",
    },
    "overtime_records": {
        "user_col": "requestor_id",
        "columns": ["overtime_record_id", "requestor_id", "approved_date",
                    "approved_start_time", "approved_end_time",
                    "clock_in_time", "clock_out_time", "is_weekend",
                    "is_holiday", "is_night_time", "status", "reason",
                    "approver_id", "rejection_reason"],
        "note": "Cột gắn user là requestor_id. Giờ OT = EXTRACT(EPOCH FROM "
                "(clock_out_time - clock_in_time))/3600 (clock_in/out là TIMESTAMP). "
                "status CHỮ THƯỜNG: 'pending' / 'accepted' / 'rejected'. "
                "OT được duyệt là 'accepted'. Dùng approved_date để gom theo năm/tháng/tuần.",
    },
    "payrolls": {
        "user_col": "user_id",
        "columns": ["payroll_id", "user_id", "period_month", "period_year",
                    "base_salary", "basic_pay", "overtime_pay",
                    "allowance_pay", "bonus_pay", "gross_pay",
                    "insurance_deduction", "tax_deduction", "other_deduction",
                    "total_deduction", "net_pay", "status", "note"],
        "note": "Phiếu lương theo tháng. Thực lĩnh = net_pay. "
                "BẮT BUỘC lấy period_year CÙNG period_month (nếu thiếu sẽ không biết năm của phiếu). "
                "Năm trong DB là NĂNG HIỆN TẠI, dùng %(year)s để lọc. "
                "KHẤU TRỪ đã có sẵn 3 cột: insurance_deduction (BHXH), tax_deduction (TNCN), "
                "other_deduction. TUYỆT ĐỐI KHÔNG tự nhân lương với tỷ lệ để tính lại — "
                "cứ lấy đúng số trong cột, nếu hỏi 'chi tiết khấu trừ' thì SELECT cả 3 cột này. "
                "status: DRAFT / APPROVED / PAID.",
    },
    "salaries": {
        "user_col": "user_id",
        "columns": ["salary_id", "user_id", "base_salary", "pay_frequency",
                    "work_days", "start_date", "end_date", "is_active"],
        "note": "Mức lương đang hiệu lực là dòng is_active = TRUE. "
                "Số ngày công CHUẨN = work_days (dòng is_active), KHÔNG SUM "
                "actual_worked_days (đó là ngày công THỰC TẾ).",
    },
    "user_contracts": {
        "user_col": "user_id",
        "columns": ["contract_id", "user_id", "contract_type",
                    "contract_start_date", "contract_end_date", "is_active"],
        "note": "Hợp đồng hiện tại là dòng is_active = TRUE.",
    },
    "user_profiles": {
        "user_col": "user_id",
        "columns": ["user_id", "phone_number", "personal_email",
                    "place_of_birth", "nationality", "marital_status",
                    "emergency_contact_name", "emergency_contact_phone",
                    "social_insurance_start_date"],
        "note": "Không chứa CCCD/BHXH/MST (đã chặn ở DB). Email CÁ NHÂN "
                "= personal_email, KHÔNG dùng users.email (email công ty).",
    },
    "user_bank_accounts": {
        "user_col": "user_id",
        "columns": ["user_id", "bank_name", "bank_code", "account_number",
                    "account_holder_name", "is_default"],
        "note": "Tài khoản nhận lương là dòng is_default = TRUE (1 nhân viên có thể có nhiều tài khoản). "
                "Nếu hỏi chung về lương thì JOIN salaries theo cùng user_id.",
    },
    "user_permission_grants": {
        "user_col": "user_id",
        "columns": ["user_id", "permission", "granted_at"],
        "note": "Quyền đặc biệt được cấp thêm của nhân viên.",
    },
    "user_sessions": {
        "user_col": "user_id",
        "columns": ["session_id", "user_id", "revoked", "last_active_at",
                    "created_at"],
        "note": "Chỉ đếm/kiểm tra trạng thái phiên (revoked TRUE/FALSE). "
                "Không có token.",
    },
    "resignation_requests": {
        "user_col": "user_id",
        "columns": ["resignation_id", "user_id", "reason", "status",
                    "submitted_time", "last_working_date",
                    "manager_approved_at", "hr_approved_at"],
        "note": "Đơn NGHỈ VIỆC / thôi việc của chính nhân viên (KHÁC "
                "leave_requests là đơn nghỉ phép). "
                "status: PENDING / MANAGER_APPROVED / MANAGER_REJECTED / "
                "APPROVED / REJECTED / CANCELLED. "
                "last_working_date là ngày cuối còn làm việc.",
    },
    "work_shifts": {
        "user_col": None,
        "columns": ["shift_id", "name"],
        "note": "Ca làm việc. JOIN qua users.shift_id hoặc attendances.shift_id.",
    },
    "work_shift_schedules": {
        "user_col": None,
        "columns": ["schedule_id", "shift_id", "day_of_week", "start_time",
                    "end_time", "rest_start_time", "rest_end_time",
                    "is_working"],
        "note": "Lịch chi tiết từng ngày trong tuần của ca. "
                "day_of_week ISO: 1=Thứ 2 ... 7=Chủ nhật (KHÔNG phải kiểu Mỹ CN=1).",
    },
    "departments": {
        "user_col": None,
        "columns": ["department_id", "name"],
        "note": "JOIN qua users.department_id để lấy tên phòng ban.",
    },
    "jobs": {
        "user_col": None,
        "columns": ["job_id", "title", "department_id"],
        "note": "JOIN qua users.job_id để lấy chức danh. TRƯỞNG PHÒNG của người hỏi "
                "= user khác cùng department_id với người hỏi (users.department_id = "
                "phòng của %(uid)s) mà jobs.title LIKE 'Department Head%'. "
                "\"Trưởng phòng / sếp / quản lý (trực tiếp) / cấp trên của tôi\" "
                "là MỘT người này (mẫu Vd18/Vd19); lịch hay chấm công của người đó "
                "thì JOIN tiếp từ alias m như Vd19, KHÔNG dùng lịch của me.",
    },
    "holidays": {
        "user_col": None,
        "columns": ["holiday_id", "date", "description"],
        "note": "Ngày lễ chung toàn công ty, dùng để trừ khi tính công.",
    },
    "performance_reviews": {
        "user_col": "user_id",
        "columns": ["review_id", "user_id", "evaluator_id", "evaluator_name",
                    "reviewee_name", "department_name", "period_year",
                    "period_month", "period_type", "avg_self", "avg_manager",
                    "overall_summary", "next_goals", "status",
                    "leader_confirmed", "self_at", "manager_at",
                    "created_at", "updated_at"],
        "note": "Đánh giá hiệu suất. Cột gắn user là user_id (người được đánh giá). "
                "evaluator_id là người đánh giá. Điểm TB tự đánh giá = avg_self, "
                "quản lý đánh = avg_manager. status: DRAFT / SUBMITTED / APPROVED / LOCKED.",
    },
    "performance_scores": {
        "user_col": None,
        "columns": ["score_id", "review_id", "criterion_code",
                    "criterion_text", "self_score", "manager_score",
                    "sort_order", "note"],
        "note": "Chi tiết điểm từng tiêu chí. KHÔNG có user_id — JOIN "
                "performance_reviews ON review_id rồi lọc reviews.user_id = %(uid)s. "
                "self_score = điểm tự chấm, manager_score = điểm quản lý chấm.",
    },
    "assets": {
        "user_col": None,
        "columns": ["asset_id", "asset_code", "name", "category_id",
                    "status", "location", "purchase_date", "purchase_cost",
                    "serial_number", "specs", "supplier", "condition_note",
                    "warranty_until", "useful_life_months", "current_holder_id",
                    "created_at", "updated_at"],
        "note": "Danh mục tài sản. JOIN asset_assignments để xem ai đang dùng, "
                "JOIN asset_categories để lấy tên loại.",
    },
    "asset_assignments": {
        "user_col": "user_id",
        "columns": ["assignment_id", "asset_id", "user_id", "department_id",
                    "assigned_at", "returned_at", "expected_return_date",
                    "status", "notes", "condition_on_assign",
                    "condition_on_return", "assigned_by", "request_id",
                    "created_at"],
        "note": "Phân bổ tài sản cho nhân viên/phòng ban. "
                "user_id NULL = tài sản dùng chung phòng ban (xem department_id). "
                "status: active / returned / pending.",
    },
    "asset_categories": {
        "user_col": None,
        "columns": ["category_id", "code_prefix", "name", "description",
                    "created_at", "updated_at"],
        "note": "Loại tài sản (Laptop, Monitor, Phone...). JOIN qua assets.category_id.",
    },
    "asset_images": {
        "user_col": None,
        "columns": ["image_id", "asset_id", "assignment_id",
                    "inventory_log_id", "maintenance_id", "image_url",
                    "caption", "is_cover", "taken_at", "taken_by"],
        "note": "Ảnh tài sản. JOIN qua asset_id.",
    },
    "asset_inventory_logs": {
        "user_col": None,
        "columns": ["log_id", "asset_id", "checked_at", "checked_by",
                    "found", "condition_note"],
        "note": "Nhật ký kiểm kê. checked_by là user_id người kiểm. "
                "found TRUE/FALSE = có tìm thấy tài sản không.",
    },
    "asset_maintenances": {
        "user_col": None,
        "columns": ["maintenance_id", "asset_id", "type", "status",
                    "description", "cost", "vendor", "sent_at",
                    "returned_at", "reported_by", "handled_by",
                    "created_at", "updated_at"],
        "note": "Bảo trì tài sản (tên bảng số nhiều). JOIN qua asset_id. "
                "reported_by là user_id người báo hỏng.",
    },
    "asset_requests": {
        "user_col": "requestor_id",
        "columns": ["request_id", "requestor_id", "category_id",
                    "reason", "needed_by_date", "expected_return_date",
                    "status", "approver_id", "rejection_reason",
                    "created_at", "updated_at"],
        "note": "Yêu cầu cấp tài sản mới. Cột gắn user là requestor_id. "
                "JOIN asset_categories để lấy tên loại cần cấp. "
                "status CHỮ THƯỜNG: 'pending' / 'approved' / 'rejected'.",
    },
    "it_tickets": {
        "user_col": "reporter_id",
        "columns": ["ticket_id", "device_info", "category", "description",
                    "location", "image_url", "priority", "reporter_id",
                    "assignee_id", "status", "resolve_note", "resolved_at",
                    "created_at", "updated_at"],
        "note": "Ticket hỗ trợ IT. Cột gắn user là reporter_id (người báo). "
                "assignee_id là IT xử lý. status CHỮ HOA: 'OPEN' / 'IN_PROGRESS' / "
                "'DONE' / 'CANCELLED' (viết thường là 0 dòng). "
                "category: LAPTOP_PC / PRINTER / NETWORK / SOFTWARE / ACCOUNT_EMAIL / PERIPHERAL / OTHER.",
    },
}

ALLOWED_TABLES = frozenset(TABLES.keys())

# Bảng gắn user -> cột ép phạm vi. SQL thiếu "cột này = %(uid)s" bị từ chối.
SCOPED_USER_COL: Dict[str, str] = {
    t: m["user_col"] for t, m in TABLES.items() if m["user_col"]
}

# Bảng dùng chung, được xuất hiện mà không cần lọc user.
GLOBAL_TABLES = frozenset(
    t for t, m in TABLES.items() if m["user_col"] is None
)


def describe_schema() -> str:
    """Render schema thành text nạp vào prompt Text-to-SQL."""
    lines = []
    for table, meta in TABLES.items():
        scope = f"user_col={meta['user_col']}" if meta["user_col"] else "global"
        lines.append(
            f"- {table} ({scope}): {', '.join(meta['columns'])}. {meta['note']}"
        )
    return "\n".join(lines)


def scoped_tables_in(sql: str) -> List[str]:
    """Bảng gắn user nào được nhắc tới trong SQL (để kiểm tra lọc uid)."""
    low = sql.lower()
    return [t for t in SCOPED_USER_COL if t in low]
