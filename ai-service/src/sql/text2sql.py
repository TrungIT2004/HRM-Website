"""Sinh SQL readonly từ câu hỏi + schema allowlist."""
import re

from .schema_registry import describe_schema

TEXT2SQL_SYSTEM = """Bạn viết đúng 1 câu SQL PostgreSQL readonly cho hệ thống HRM.
Schema cho phép (bảng: cột. user_col là cột bắt buộc lọc theo người hỏi):
{SCHEMA}

--- LUẬT CỨNG (vi phạm là SQL bị loại):
1. Chỉ SELECT hoặc WITH...SELECT. Cấm INSERT/UPDATE/DELETE/DROP/ALTER/CREATE/TRUNCATE/COPY/GRANT và mọi dấu ; -- /*
2. Mỗi bảng gắn user xuất hiện trong SQL PHẢI có điều kiện "<bảng hoặc alias>.<user_col> = %(uid)s".
   leave_requests và overtime_records dùng requestor_id, các bảng còn lại dùng user_id.
3. Cấm SELECT *. Liệt kê cột rõ ràng, chỉ dùng cột trong schema trên.
4. Chỉ dùng placeholder %(uid)s và %(year)s. Năm hiện tại: %(year)s. Không tự bịa UUID.
5. Ưu tiên bảng tổng hợp monthly_timesheets cho câu hỏi tổng giờ/ngày theo tháng/năm.
6. Trả về duy nhất 1 khối ```sql ... ```, không giải thích.
"""

FEW_SHOTS = """
Vd1: "Tôi còn bao nhiêu ngày phép?"
```sql
SELECT annual_leave_days, used_leave_days,
       (annual_leave_days - used_leave_days) AS remaining_days
FROM users WHERE users.user_id = %(uid)s
```

Vd2: "Năm nay tôi làm tổng cộng bao nhiêu giờ?"
```sql
SELECT COALESCE(SUM(mt.actual_work_hours), 0) AS total_hours,
       COALESCE(SUM(mt.actual_worked_days), 0) AS total_days
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s
```

Vd3: "Tháng này tôi đi muộn mấy lần, tổng bao nhiêu phút?"
```sql
SELECT mt.period_month, mt.late_count, mt.total_late_minutes
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s
ORDER BY mt.period_month DESC LIMIT 3
```

Vd4: "Lương và ngân hàng của tôi?" — nhiều bảng thì JOIN thẳng, KHÔNG dùng CTE/LATERAL.
```sql
SELECT s.base_salary, s.pay_frequency, b.bank_name, b.account_number,
       b.account_holder_name
FROM salaries s
LEFT JOIN user_bank_accounts b ON b.user_id = s.user_id AND b.user_id = %(uid)s
    AND b.is_default = TRUE
WHERE s.user_id = %(uid)s AND s.is_active = TRUE
```

Vd5: "Lương từng tháng trong năm nay?" — BẮT BUỘC lấy CẢ period_year trong SELECT
và trong WHERE, nếu không LLM sẽ không biết năm của phiếu lương.
```sql
SELECT p.period_month, p.period_year, p.base_salary, p.net_pay, p.status
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = %(year)s
ORDER BY p.period_year, p.period_month
```

Vd6: "Tổng lương năm nay?" — chỉ cần 1 con số, dùng SUM chứ không liệt kê từng tháng.
```sql
SELECT COALESCE(SUM(p.net_pay), 0) AS tong_thuc_nhan, COUNT(*) AS so_phieu
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = %(year)s
```

Vd7: "Giải thích rõ số khấu trừ từng khoản?" — DB ĐÃ CÓ sẵn 3 cột khấu trừ,
chỉ SELECT ra, KHÔNG tự nhân lương với tỷ lệ % để tính lại.
```sql
SELECT p.period_month, p.period_year, p.base_salary, p.gross_pay,
       p.insurance_deduction, p.tax_deduction, p.other_deduction,
       p.total_deduction, p.net_pay
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = %(year)s
ORDER BY p.period_year, p.period_month
```

--- BIẾN THỂ TRUY VẤN (dùng đúng mẫu bên dưới, đổi bảng/cột theo schema) ---

Vd8: TỔNG theo năm/tháng — GROUP BY + SUM
```sql
SELECT EXTRACT(MONTH FROM o.approved_date)::int AS thang,
       COUNT(*) AS so_don,
       SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600) AS tong_gio
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted'
  AND EXTRACT(YEAR FROM o.approved_date) = %(year)s
GROUP BY 1 ORDER BY 1
```

Vd9: SO SÁNH với kỳ trước — dùng subquery + CTE (được phép, tên CTE tự đặt)
```sql
WITH nam_nay AS (
    SELECT COALESCE(SUM(mt.actual_work_hours), 0) AS gio
    FROM monthly_timesheets mt
    WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s
), nam_truoc AS (
    SELECT COALESCE(SUM(mt.actual_work_hours), 0) AS gio
    FROM monthly_timesheets mt
    WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s - 1
)
SELECT nam_nay.gio AS gio_nam_nay, nam_truoc.gio AS gio_nam_truoc,
       nam_nay.gio - nam_truoc.gio AS chenh_biet
FROM nam_nay, nam_truoc
```

Vd10: LỌC THEO TRẠNG THÁI — CHÚ Ý status của mỗi bảng khác nhau (xem note schema)
```sql
SELECT lr.from_date, lr.to_date, lr.paid_leave_days, lr.status, lr.reason
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s AND lr.status = 'accepted'
ORDER BY lr.from_date DESC
```

Vd11: THEO TUẦN — dùng date_trunc, không có cột tuần sẵn
```sql
SELECT to_char(date_trunc('week', a.work_date), 'YYYY-MM-DD') AS tuan,
       SUM(EXTRACT(EPOCH FROM (a.clock_out_time - a.clock_in_time))/3600) AS gio
FROM attendances a
WHERE a.user_id = %(uid)s AND a.is_deleted = FALSE
GROUP BY 1 ORDER BY 1
```

Vd12: ĐẾM + ĐIỀU KIỆN SO SÁNH — HAVING cho điều kiện trên nhóm
```sql
SELECT EXTRACT(MONTH FROM o.approved_date)::int AS thang,
       COUNT(*) AS so_don,
       SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600) AS gio_ot
FROM overtime_records o
WHERE o.requestor_id = %(uid)s
  AND o.status = 'accepted'
  AND EXTRACT(YEAR FROM o.approved_date) = %(year)s
GROUP BY 1 HAVING COUNT(*) > 0 ORDER BY 1
```

Vd13: GIỚI HẠN SỐ DÒNG — luôn có LIMIT khi liệt kê chi tiết
```sql
SELECT lr.from_date, lr.to_date, lr.reason
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s
ORDER BY lr.from_date DESC LIMIT 20
```

Vd13: LỊCH LÀM VIỆC của tôi — work_shifts (global) + work_shift_schedules (global)
qua users.shift_id, KHÔNG cần %(uid)s vì 2 bảng này không gắn user.
```sql
SELECT wss.day_of_week, wss.is_working, wss.start_time, wss.end_time, ws.name AS ten_ca
FROM users u
JOIN work_shifts ws ON ws.shift_id = u.shift_id
JOIN work_shift_schedules wss ON wss.shift_id = ws.shift_id
WHERE u.user_id = %(uid)s
ORDER BY wss.day_of_week
```

Vd14: Ngày lễ toàn công ty — bảng global, không gắn user.
```sql
SELECT h.date, h.description FROM holidays h
WHERE EXTRACT(YEAR FROM h.date) = %(year)s ORDER BY h.date
```

Vd15: ĐẾM phải trả 1 dòng kể cả khi bằng 0 (không HAVING lọc hết).
```sql
SELECT COUNT(*) AS so_lan FROM attendances a
WHERE a.user_id = %(uid)s AND a.status = 'LATE'
  AND EXTRACT(MONTH FROM a.work_date) = EXTRACT(MONTH FROM CURRENT_DATE)
```

Vd16: So sánh với kỳ trước KHÔNG tồn tại thì chênh lệch = 0
(không lấy lương hiện tại làm chênh lệch).
```sql
SELECT s.base_salary AS hien_tai,
       COALESCE((SELECT s2.base_salary FROM salaries s2
                 WHERE s2.user_id = %(uid)s AND s2.is_active = FALSE
                 ORDER BY s2.start_date DESC LIMIT 1), 0) AS truoc_do,
       CASE WHEN EXISTS (SELECT 1 FROM salaries s2
                         WHERE s2.user_id = %(uid)s AND s2.is_active = FALSE)
            THEN s.base_salary - (SELECT s2.base_salary FROM salaries s2
                                  WHERE s2.user_id = %(uid)s AND s2.is_active = FALSE
                                  ORDER BY s2.start_date DESC LIMIT 1)
            ELSE 0 END AS chenh_lech
FROM salaries s
WHERE s.user_id = %(uid)s AND s.is_active = TRUE
```

Vd17: Liệt kê đơn — LUÔN kèm ngày + lý do + trạng thái.
```sql
SELECT lr.from_date, lr.to_date, lr.reason, lr.status
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s
ORDER BY lr.from_date DESC LIMIT 20
```

Vd18: TRƯỞNG PHÒNG CỦA TÔI — self-join users (me = người hỏi) với users
cùng department_id có jobs.title LIKE 'Department Head%'. Điều kiện
me.user_id = %(uid)s thỏa luật lọc user (bảng users chỉ cần 1 lần lọc).
```sql
SELECT m.first_name, m.last_name, m.email, p.phone_number, j.title AS chuc_danh
FROM users me
JOIN users m ON m.department_id = me.department_id
LEFT JOIN jobs j ON j.job_id = m.job_id
LEFT JOIN user_profiles p ON p.user_id = m.user_id
WHERE me.user_id = %(uid)s AND m.is_active = TRUE
  AND j.title LIKE 'Department Head%' LIMIT 5
```

Vd19: LỊCH LÀM VIỆC CỦA TRƯỞNG PHÒNG/SẾP/QUẢN LÝ TRỰC TIẾP CỦA TÔI —
giống Vd18 để tìm m, rồi JOIN lịch theo m.shift_id (KHÔNG dùng shift của me).
Trả cả tuần, Composer tự đối chiếu "mai"/"hôm nay" theo day_of_week.
```sql
SELECT wss.day_of_week, wss.is_working, wss.start_time, wss.end_time,
       ws.name AS ten_ca
FROM users me
JOIN users m ON m.department_id = me.department_id
JOIN work_shifts ws ON ws.shift_id = m.shift_id
JOIN work_shift_schedules wss ON wss.shift_id = ws.shift_id
LEFT JOIN jobs j ON j.job_id = m.job_id
WHERE me.user_id = %(uid)s AND m.is_active = TRUE
  AND j.title LIKE 'Department Head%'
ORDER BY wss.day_of_week
```

LƯU Ý:
1. Chỉ dùng tên bảng có trong danh sách trên. KHÔNG tự đặt tên bảng phụ trong FROM/JOIN
   (active_salary, latest_payroll...) — nếu cần tên riêng thì dùng CTE có `WITH ten AS (...)`.
2. Cột gắn user là `user_id`, RIÊNG leave_requests và overtime_records dùng `requestor_id`.
3. DatePart: `EXTRACT(YEAR|MONTH|DAY FROM ...)`, tuần dùng `date_trunc('week', ...)`.
4. Giờ làm việc = `EXTRACT(EPOCH FROM (clock_out_time - clock_in_time))/3600`.
5. Lọc dữ liệu đã xoá: `is_deleted = FALSE`.
6. Luôn có LIMIT (tối đa 100) khi liệt kê chi tiết, dùng SUM/COUNT thì không cần.
7. Năm hiện tại dùng %(year)s; năm trước dùng `%(year)s - 1`.
8. Cần tên người liên quan (duyệt/cấp/xử lý/đánh giá): chỉ SELECT cột id
   (approver_id, assigned_by, assignee_id, evaluator_id...), KHÔNG JOIN users —
   hệ thống tự tra cứu tên sau. NGOẠI LỆ duy nhất: "trưởng phòng / sếp /
   quản lý (trực tiếp) của tôi" (một người) thì JOIN users theo mẫu Vd18
   (danh tính) / Vd19 (lịch làm việc của người đó).
9. Liệt kê đơn/phiếu/ticket: luôn SELECT kèm ngày + lý do/mô tả + trạng thái,
   không chỉ cột trạng thái (đáp án chỉ có status mà thiếu ngữ cảnh là không đạt).
10. Đếm số lượng (COUNT) luôn trả 1 dòng kể cả khi bằng 0 — dùng COUNT/COALESCE,
    không dùng HAVING lọc hết nhóm rỗng.
11. So sánh với kỳ trước không tồn tại (chỉ 1 dòng lương/hợp đồng) thì chênh
    lệch = 0 — không lấy giá trị hiện tại làm chênh lệch. Trừ 2 cột DATE ra
    số ngày nguyên, cấm EXTRACT(EPOCH...) trên kiểu date.
"""


def build_text2sql_prompt(question: str) -> str:
    from datetime import date
    system = TEXT2SQL_SYSTEM.replace("{SCHEMA}", describe_schema())
    system = system.replace("%(year)s", str(date.today().year))
    return f"{system}\n{FEW_SHOTS}\nCâu hỏi: {question}\n```sql"


def extract_sql(text: str) -> str:
    """Lấy SQL trong khối ```sql, fallback lấy dòng SELECT đầu tiên."""
    m = re.search(r"```sql(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if m:
        return m.group(1).strip().rstrip(";").strip()
    m = re.search(r"(SELECT|WITH)\b.*", text, re.DOTALL | re.IGNORECASE)
    return (m.group(0).strip().rstrip(";").strip() if m else "")
