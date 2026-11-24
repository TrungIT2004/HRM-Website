# -*- coding: utf-8 -*-
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
5. Ưu tiên monthly_timesheets cho tổng hợp giờ/ngày/đi muộn theo tháng/năm; luôn có LIMIT tối đa 100 khi liệt kê chi tiết.
6. Trả về duy nhất 1 khối ```sql ... ```, không giải thích, không comment.
"""

FEW_SHOTS = """
Vd1: "Tôi còn bao nhiêu ngày phép?" -- users, chỉ select
```sql
SELECT annual_leave_days, used_leave_days,
       (annual_leave_days - used_leave_days) AS remaining_days
FROM users WHERE user_id = %(uid)s
```

Vd2: "Năm nay tôi làm tổng cộng bao nhiêu giờ?" -- monthly_timesheets + SUM + %(year)s
```sql
SELECT COALESCE(SUM(mt.actual_work_hours), 0) AS total_hours,
       COALESCE(SUM(mt.actual_worked_days), 0) AS total_days
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s
```

Vd3: "Tháng này tôi đi muộn mấy lần?" -- monthly_timesheets lấy kỳ gần nhất, KHÔNG dùng CURRENT_DATE
```sql
SELECT mt.period_month, mt.late_count, mt.total_late_minutes
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s
ORDER BY mt.period_year DESC, mt.period_month DESC LIMIT 1
```

Vd4: "Lương và ngân hàng của tôi?" -- JOIN thẳng, LEFT JOIN cho bảng có thể thiếu (có user_id = %(uid)s ở ON)
```sql
SELECT s.base_salary, s.pay_frequency, b.bank_name, b.account_number, b.account_holder_name
FROM salaries s
LEFT JOIN user_bank_accounts b ON b.user_id = s.user_id AND b.user_id = %(uid)s AND b.is_default = TRUE
WHERE s.user_id = %(uid)s AND s.is_active = TRUE
```

Vd5: "Lương từng tháng trong năm nay?" -- payrolls, có LIMIT, SELECT period_year
```sql
SELECT p.period_month, p.period_year, p.base_salary, p.net_pay, p.status
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = %(year)s
ORDER BY p.period_year, p.period_month LIMIT 100
```

Vd6: "Tổng lương năm nay?" -- SUM/COUNT, không GROUP BY, luôn trả 1 dòng
```sql
SELECT COALESCE(SUM(p.net_pay), 0) AS tong_thuc_nhan, COUNT(*) AS so_phieu
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = %(year)s
```

Vd7: "So sánh năm nay vs năm trước an toàn khi thiếu dữ liệu" -- scalar subquery thay CROSS JOIN
```sql
SELECT
    (SELECT COALESCE(SUM(mt.actual_work_hours), 0) FROM monthly_timesheets mt WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s) AS gio_nam_nay,
    (SELECT COALESCE(SUM(mt.actual_work_hours), 0) FROM monthly_timesheets mt WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s - 1) AS gio_nam_truoc
```

Vd8: "Phiếu lương kỳ gần nhất" -- ORDER BY DESC LIMIT 1, KHÔNG lọc tháng/năm hiện tại
```sql
SELECT p.period_month, p.period_year, p.net_pay, p.status
FROM payrolls p
WHERE p.user_id = %(uid)s
ORDER BY p.period_year DESC, p.period_month DESC LIMIT 1
```

Vd9: "Nghỉ phép chi tiết" -- leave_requests, requestor_id, is_deleted = FALSE, LIMIT
```sql
SELECT lr.from_date, lr.to_date, lr.reason, lr.status
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s AND lr.is_deleted = FALSE
ORDER BY lr.from_date DESC LIMIT 20
```

Vd10: "Tăng ca chi tiết" -- overtime_records, requestor_id, approved_date/approved_start_time/approved_end_time, EXTRACT(EPOCH)/3600, LIMIT
```sql
SELECT o.approved_date, o.approved_start_time, o.approved_end_time, o.reason, o.status,
       EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600 AS gio_ot
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted'
ORDER BY o.approved_date DESC LIMIT 20
```

Vd11: "Trưởng phòng của tôi" -- self-join users, loại trừ chính mình, LIMIT 1
```sql
SELECT m.first_name, m.last_name, m.email, j.title AS chuc_danh
FROM users me
JOIN users m ON m.department_id = me.department_id
LEFT JOIN jobs j ON j.job_id = m.job_id
WHERE me.user_id = %(uid)s AND m.user_id <> me.user_id
  AND m.is_active = TRUE AND j.title LIKE 'Department Head%' LIMIT 1
```

Vd12: "Ngày lễ toàn công ty" -- bảng global, không gắn user
```sql
SELECT h.date, h.description FROM holidays h
WHERE EXTRACT(YEAR FROM h.date) = %(year)s ORDER BY h.date
```

Vd13: "Thâm niên năm tháng" -- EXTRACT(YEAR/MONTH FROM AGE)::int
```sql
SELECT joined_date,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, joined_date))::int AS years,
       EXTRACT(MONTH FROM AGE(CURRENT_DATE, joined_date))::int AS months
FROM users WHERE user_id = %(uid)s
```

Vd14: "Tính % phép đã dùng" -- ROUND, ::numeric, NULLIF tránh chia 0
```sql
SELECT annual_leave_days, used_leave_days,
       ROUND(used_leave_days::numeric / NULLIF(annual_leave_days, 0) * 100, 1) AS used_pct
FROM users WHERE user_id = %(uid)s
```

Vd15: "So sánh tháng này vs tháng trước" -- scalar subquery + CTE tham số (mẫu gold SQL)
```sql
WITH m AS (
    SELECT date_trunc('month', CURRENT_DATE)::date AS cur,
           (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date AS prev
)
SELECT (SELECT COUNT(*) FROM attendances, m WHERE user_id = %(uid)s AND is_deleted = FALSE
        AND status IN ('LATE','LATE_AND_EARLY') AND work_date >= m.cur AND work_date < m.cur + INTERVAL '1 month') AS this_month,
       (SELECT COUNT(*) FROM attendances, m WHERE user_id = %(uid)s AND is_deleted = FALSE
        AND status IN ('LATE','LATE_AND_EARLY') AND work_date >= m.prev AND work_date < m.cur) AS last_month
```

Vd16: "So sánh quý này vs quý trước" -- EXTRACT(QUARTER), scalar subquery
```sql
WITH q AS (SELECT EXTRACT(QUARTER FROM CURRENT_DATE)::int AS cur)
SELECT (SELECT COALESCE(SUM(paid_leave_days),0) FROM leave_requests, q
        WHERE requestor_id = %(uid)s AND status = 'accepted'
          AND EXTRACT(QUARTER FROM from_date) = q.cur AND EXTRACT(YEAR FROM from_date) = EXTRACT(YEAR FROM CURRENT_DATE)) AS this_quarter,
       (SELECT COALESCE(SUM(paid_leave_days),0) FROM leave_requests, q
        WHERE requestor_id = %(uid)s AND status = 'accepted'
          AND EXTRACT(QUARTER FROM from_date) = q.cur - 1 AND EXTRACT(YEAR FROM from_date) = EXTRACT(YEAR FROM CURRENT_DATE)) AS last_quarter
```

Vd17: "So sánh năm nay vs năm ngoái" -- EXTRACT(YEAR), scalar subquery
```sql
WITH y AS (SELECT EXTRACT(YEAR FROM CURRENT_DATE)::int AS cur)
SELECT (SELECT COALESCE(SUM(actual_work_hours),0) FROM monthly_timesheets, y WHERE user_id = %(uid)s AND period_year = y.cur) AS this_year,
       (SELECT COALESCE(SUM(actual_work_hours),0) FROM monthly_timesheets, y WHERE user_id = %(uid)s AND period_year = y.cur - 1) AS last_year
```

Vd18: "Tháng này vs tháng trước (giờ làm)" -- monthly_timesheets, scalar subquery
```sql
WITH m AS (
    SELECT date_trunc('month', CURRENT_DATE)::date AS cur,
           (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date AS prev
)
SELECT (SELECT COALESCE(SUM(actual_work_hours),0) FROM monthly_timesheets, m WHERE user_id = %(uid)s AND period_year = EXTRACT(YEAR FROM m.cur)::int AND period_month = EXTRACT(MONTH FROM m.cur)::int) AS this_month,
       (SELECT COALESCE(SUM(actual_work_hours),0) FROM monthly_timesheets, m WHERE user_id = %(uid)s AND period_year = EXTRACT(YEAR FROM m.prev)::int AND period_month = EXTRACT(MONTH FROM m.prev)::int) AS last_month
```

Vd19: "Phân nhóm theo tháng + FILTER" -- COUNT FILTER cho late/early
```sql
SELECT EXTRACT(MONTH FROM work_date)::int AS month,
       COUNT(*) FILTER (WHERE status IN ('LATE','LATE_AND_EARLY')) AS late_count,
       COUNT(*) FILTER (WHERE status = 'EARLY') AS early_count
FROM attendances
WHERE user_id = %(uid)s AND is_deleted = FALSE AND EXTRACT(YEAR FROM work_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1 ORDER BY 1
```

Vd20: "Tháng nào đi muộn nhất" -- GROUP BY + ORDER BY COUNT DESC LIMIT 1
```sql
SELECT EXTRACT(MONTH FROM work_date)::int AS month, COUNT(*) AS late_count
FROM attendances
WHERE user_id = %(uid)s AND is_deleted = FALSE AND status IN ('LATE','LATE_AND_EARLY')
  AND EXTRACT(YEAR FROM work_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1 ORDER BY late_count DESC LIMIT 1
```

Vd21: "Tổng giờ làm tuần này" -- date_trunc week + EXTRACT EPOCH
```sql
SELECT ROUND(SUM(EXTRACT(EPOCH FROM (clock_out_time - clock_in_time))/3600)::numeric, 2) AS total_hours
FROM attendances
WHERE user_id = %(uid)s AND is_deleted = FALSE
  AND clock_in_time IS NOT NULL AND clock_out_time IS NOT NULL
  AND work_date >= date_trunc('week', CURRENT_DATE)::date
```

Vd22: "Giờ OT đêm/cuối tuần/ngày lễ" -- FILTER (WHERE is_night_time/is_weekend/is_holiday)
```sql
SELECT ROUND(COALESCE(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600) FILTER (WHERE o.is_night_time = TRUE),0)::numeric, 2) AS night_hours,
       ROUND(COALESCE(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600) FILTER (WHERE o.is_weekend = TRUE),0)::numeric, 2) AS weekend_hours,
       ROUND(COALESCE(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600) FILTER (WHERE o.is_holiday = TRUE),0)::numeric, 2) AS holiday_hours
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted' AND EXTRACT(YEAR FROM o.approved_date) = EXTRACT(YEAR FROM CURRENT_DATE)
```

Vd23: "Tổng giờ OT năm nay" -- ROUND, ::numeric, COALESCE
```sql
SELECT ROUND(COALESCE(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600),0)::numeric, 2) AS total_ot_hours
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted' AND EXTRACT(YEAR FROM o.approved_date) = EXTRACT(YEAR FROM CURRENT_DATE)
```

Vd24: "OT theo tháng" -- EXTRACT(MONTH)::int, ROUND, GROUP BY
```sql
SELECT EXTRACT(MONTH FROM o.approved_date)::int AS month,
       ROUND(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600)::numeric, 2) AS total_hours,
       COUNT(*) AS cnt
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted' AND EXTRACT(YEAR FROM o.approved_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1 ORDER BY 1
```

Vd25: "Tháng OT nhiều nhất" -- GROUP BY + ORDER BY SUM DESC LIMIT 1
```sql
SELECT EXTRACT(MONTH FROM o.approved_date)::int AS month,
       ROUND(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600)::numeric, 2) AS total_hours
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted' AND EXTRACT(YEAR FROM o.approved_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1 ORDER BY total_hours DESC LIMIT 1
```

Vd26: "Tuần OT nhiều nhất" -- date_trunc week + GROUP BY
```sql
SELECT date_trunc('week', o.approved_date)::date AS week,
       ROUND(SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600)::numeric, 2) AS total_hours
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted' AND EXTRACT(YEAR FROM o.approved_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1 ORDER BY total_hours DESC LIMIT 1
```

Vd27: "COUNT + AVG" -- COUNT(*) + AVG(EXTRACT EPOCH)
```sql
SELECT COUNT(*) AS cnt, ROUND(AVG(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600)::numeric, 2) AS avg_hours
FROM overtime_records o
WHERE o.requestor_id = %(uid)s AND o.status = 'accepted' AND EXTRACT(YEAR FROM o.approved_date) = EXTRACT(YEAR FROM CURRENT_DATE)
```

Vd28: "Lương tháng này" -- ORDER BY DESC LIMIT 1 (KHÔNG lọc tháng hiện tại)
```sql
SELECT p.period_month, p.period_year, p.net_pay, p.status
FROM payrolls p
WHERE p.user_id = %(uid)s
ORDER BY p.period_year DESC, p.period_month DESC LIMIT 1
```

Vd29: "Tổng lương năm nay" -- SUM net_pay + %(year)s
```sql
SELECT COALESCE(SUM(p.net_pay), 0) AS total_net
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int
```

Vd30: "Lương từng tháng" -- period_year trong SELECT và WHERE
```sql
SELECT p.period_month, p.period_year, p.base_salary, p.net_pay, p.status
FROM payrolls p
WHERE p.user_id = %(uid)s AND p.period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int
ORDER BY p.period_month
```

Vd31: "Nghỉ phép năm nay" -- SUM paid_leave_days + status accepted + EXTRACT YEAR
```sql
SELECT COALESCE(SUM(lr.paid_leave_days), 0) AS total_paid_leave
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s AND lr.status = 'accepted' AND EXTRACT(YEAR FROM lr.from_date) = EXTRACT(YEAR FROM CURRENT_DATE)
```

Vd32: "Đơn nghỉ gần nhất" -- ORDER BY created_at DESC LIMIT 1
```sql
SELECT lr.from_date, lr.to_date, lr.status, lr.reason
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s
ORDER BY lr.created_at DESC LIMIT 1
```

Vd33: "Thống kê đơn theo status" -- GROUP BY status + COUNT
```sql
SELECT lr.status, COUNT(*) AS cnt
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s
GROUP BY lr.status ORDER BY lr.status
```

Vd34: "Tháng nghỉ nhiều nhất" -- GROUP BY month + SUM + ORDER BY DESC LIMIT 1
```sql
SELECT EXTRACT(MONTH FROM lr.from_date)::int AS month, SUM(lr.paid_leave_days) AS total_days
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s AND lr.status = 'accepted' AND EXTRACT(YEAR FROM lr.from_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1 ORDER BY total_days DESC LIMIT 1
```

Vd35: "Liệt kê đơn nghỉ" -- LIMIT 10, đầy đủ cột
```sql
SELECT lr.from_date, lr.to_date, lr.reason, lr.status
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s
ORDER BY lr.from_date DESC LIMIT 10
```

Vd36: "Đơn bị từ chối" -- status rejected + rejection_reason
```sql
SELECT lr.from_date, lr.to_date, lr.status, lr.rejection_reason
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s AND lr.status = 'rejected' ORDER BY lr.from_date DESC
```

Vd37: "So sánh quý này vs quý trước (phép)" -- scalar subquery + EXTRACT QUARTER
```sql
WITH q AS (SELECT EXTRACT(QUARTER FROM CURRENT_DATE)::int AS cur)
SELECT (SELECT COALESCE(SUM(lr.paid_leave_days),0) FROM leave_requests, q
        WHERE lr.requestor_id = %(uid)s AND lr.status = 'accepted'
          AND EXTRACT(QUARTER FROM lr.from_date) = q.cur AND EXTRACT(YEAR FROM lr.from_date) = EXTRACT(YEAR FROM CURRENT_DATE)) AS this_quarter,
       (SELECT COALESCE(SUM(lr.paid_leave_days),0) FROM leave_requests, q
        WHERE lr.requestor_id = %(uid)s AND lr.status = 'accepted'
          AND EXTRACT(QUARTER FROM lr.from_date) = q.cur - 1 AND EXTRACT(YEAR FROM lr.from_date) = EXTRACT(YEAR FROM CURRENT_DATE)) AS last_quarter
```

Vd38: "Đơn chờ duyệt" -- status pending
```sql
SELECT lr.from_date, lr.to_date, lr.status, lr.reason
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s AND lr.status = 'pending' ORDER BY lr.from_date
```

Vd39: "Người duyệt đơn gần nhất" -- approver_id + ORDER BY created_at
```sql
SELECT lr.approver_id, lr.from_date, lr.status
FROM leave_requests lr
WHERE lr.requestor_id = %(uid)s
ORDER BY lr.created_at DESC LIMIT 1
```

Vd40: "Bảng chấm công hôm nay" -- CURRENT_DATE + is_deleted
```sql
SELECT a.work_date, a.clock_in_time, a.clock_out_time, a.status
FROM attendances a
WHERE a.user_id = %(uid)s AND a.is_deleted = FALSE AND a.work_date = CURRENT_DATE
```

Vd41: "Ngày vắng không phép" -- UNEXCUSED_ABSENCE + date_trunc month
```sql
SELECT a.work_date, a.status
FROM attendances a
WHERE a.user_id = %(uid)s AND a.is_deleted = FALSE
  AND a.status = 'UNEXCUSED_ABSENCE'
  AND a.work_date >= date_trunc('month', CURRENT_DATE)::date
ORDER BY a.work_date LIMIT 20
```

Vd42: "Lịch sử chấm công 10 ngày" -- ORDER BY DESC LIMIT 10
```sql
SELECT a.work_date, a.clock_in_time, a.clock_out_time, a.status
FROM attendances a
WHERE a.user_id = %(uid)s AND a.is_deleted = FALSE
ORDER BY a.work_date DESC LIMIT 10
```

Vd43: "Tháng này vs tháng trước (late_count từ monthly_timesheets)" -- scalar subquery
```sql
WITH m AS (
    SELECT date_trunc('month', CURRENT_DATE)::date AS cur,
           (date_trunc('month', CURRENT_DATE) - INTERVAL '1 month')::date AS prev
)
SELECT (SELECT COALESCE(mt.late_count,0) FROM monthly_timesheets mt, m WHERE mt.user_id = %(uid)s AND mt.period_year = EXTRACT(YEAR FROM m.cur)::int AND mt.period_month = EXTRACT(MONTH FROM m.cur)::int) AS this_month,
       (SELECT COALESCE(mt.late_count,0) FROM monthly_timesheets mt, m WHERE mt.user_id = %(uid)s AND mt.period_year = EXTRACT(YEAR FROM m.prev)::int AND mt.period_month = EXTRACT(MONTH FROM m.prev)::int) AS last_month
```

Vd44: "Tháng nào nghỉ không lương nhiều nhất" -- ORDER BY unpaid_leave_days DESC LIMIT 1
```sql
SELECT mt.period_month, mt.unpaid_leave_days
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int
ORDER BY mt.unpaid_leave_days DESC LIMIT 1
```

Vd45: "Quý 1: nghỉ phép + vắng mặt" -- BETWEEN 1 AND 3
```sql
SELECT COALESCE(SUM(mt.paid_leave_days),0) AS paid_leave_days,
       COALESCE(SUM(mt.absent_days),0) AS absent_days
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int AND mt.period_month BETWEEN 1 AND 3
```

Vd46: "OT thực tế vs OT được trả" -- hiệu 2 cột
```sql
SELECT mt.period_month, mt.total_actual_ot_hours, mt.total_paid_ot_hours,
       (mt.total_actual_ot_hours - mt.total_paid_ot_hours) AS diff_hours
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int AND mt.period_month = EXTRACT(MONTH FROM CURRENT_DATE)::int
```

Vd47: "Tháng late_count > 3" -- HAVING
```sql
SELECT mt.period_month, mt.late_count
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s AND mt.period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int AND mt.late_count > 3
ORDER BY mt.period_month
```

Vd48: "Bảng công 3 tháng gần nhất" -- ORDER BY DESC LIMIT 3
```sql
SELECT mt.period_year, mt.period_month, mt.actual_work_hours, mt.late_count, mt.total_late_minutes
FROM monthly_timesheets mt
WHERE mt.user_id = %(uid)s
ORDER BY mt.period_year DESC, mt.period_month DESC LIMIT 3
```

Vd49: "Phòng ban, chức danh, ca làm" -- 3 LEFT JOIN
```sql
SELECT u.employee_code, d.name AS department, j.title AS job, s.name AS shift
FROM users u
LEFT JOIN departments d ON d.department_id = u.department_id
LEFT JOIN jobs j ON j.job_id = u.job_id
LEFT JOIN work_shifts s ON s.shift_id = u.shift_id
WHERE u.user_id = %(uid)s
```

Vd50: "Hợp đồng thử việc" -- contract_type = 'Probation' + duration
```sql
SELECT c.contract_type, c.contract_start_date, c.contract_end_date,
       (c.contract_end_date - c.contract_start_date) AS duration_days
FROM user_contracts c
WHERE c.user_id = %(uid)s AND c.contract_type = 'Probation'
ORDER BY c.contract_start_date DESC LIMIT 1
```

Vd51: "Hợp đồng sắp hết hạn 60 ngày" -- BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL
```sql
SELECT c.contract_type, c.contract_start_date, c.contract_end_date, c.is_active
FROM user_contracts c
WHERE c.user_id = %(uid)s AND c.is_active = TRUE
  AND c.contract_end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '60 days'
```

Vd52: "Thông tin ngân hàng mặc định" -- is_default = TRUE
```sql
SELECT b.bank_name, b.account_number, b.account_holder_name
FROM user_bank_accounts b
WHERE b.user_id = %(uid)s AND b.is_default = TRUE
```

Vd53: "Kiểm tra NULL profile" -- CASE WHEN IS NULL
```sql
SELECT CASE WHEN p.phone_number IS NULL THEN 'missing_phone' END AS missing_phone,
       CASE WHEN p.personal_email IS NULL THEN 'missing_email' END AS missing_email,
       CASE WHEN p.emergency_contact_name IS NULL THEN 'missing_emergency_name' END AS missing_emergency_name,
       CASE WHEN p.emergency_contact_phone IS NULL THEN 'missing_emergency_phone' END AS missing_emergency_phone
FROM user_profiles p WHERE p.user_id = %(uid)s
```

Vd54: "Tài sản đang giữ" -- asset_assignments status active
```sql
SELECT a.asset_id, ast.name AS asset_name, aa.assigned_at, aa.condition_on_assign
FROM asset_assignments aa
JOIN assets a ON a.asset_id = aa.asset_id
JOIN asset_categories ast ON ast.category_id = a.category_id
WHERE aa.user_id = %(uid)s AND aa.status = 'active'
ORDER BY aa.assigned_at DESC
```

Vd55: "Yêu cầu tài sản pending" -- asset_requests status pending
```sql
SELECT ar.request_id, ar.category_id, ar.reason, ar.needed_by_date, ar.status
FROM asset_requests ar
WHERE ar.requestor_id = %(uid)s AND ar.status = 'pending'
ORDER BY ar.created_at DESC
```

Vd56: "Ticket IT của tôi" -- it_tickets reporter_id
```sql
SELECT it.ticket_id, it.category, it.description, it.status, it.priority, it.created_at
FROM it_tickets it
WHERE it.reporter_id = %(uid)s
ORDER BY it.created_at DESC
```

Vd57: "Quyền của tôi" -- user_permission_grants
```sql
SELECT p.permission, p.granted_at
FROM user_permission_grants p
WHERE p.user_id = %(uid)s
ORDER BY p.granted_at DESC
```

Vd58: "Phiên đăng nhập hôm nay" -- user_sessions hôm nay
```sql
SELECT s.session_id, s.created_at, s.last_active_at, s.revoked
FROM user_sessions s
WHERE s.user_id = %(uid)s AND s.created_at >= CURRENT_DATE
ORDER BY s.created_at DESC
```

Vd59: "Đơn từ chối việc" -- resignation_requests status rejected
```sql
SELECT r.resignation_id, r.reason, r.status, r.submitted_time, r.last_working_date
FROM resignation_requests r
WHERE r.user_id = %(uid)s AND r.status IN ('rejected','cancelled')
ORDER BY r.submitted_time DESC
```

Vd60: "Hợp đồng không xác định thời hạn" -- contract_type Indefinite
```sql
SELECT c.contract_type, c.contract_start_date, c.contract_end_date, c.is_active
FROM user_contracts c
WHERE c.user_id = %(uid)s AND c.contract_type = 'Indefinite'
ORDER BY c.contract_start_date DESC LIMIT 1
"""

def build_text2sql_prompt(question: str) -> str:
    system = TEXT2SQL_SYSTEM.replace("{SCHEMA}", describe_schema())
    # %(year)s is a placeholder the LLM must emit verbatim; do NOT replace it.
    return f"{system}\n{FEW_SHOTS}\nCâu hỏi: {question}\n```sql"


def extract_sql(text: str) -> str:
    """Lấy SQL trong khối ```sql, fallback lấy dòng SELECT/WITH đầu tiên (cắt trước ``` nếu có)."""
    m = re.search(r"```sql\s*(.*?)\s*```", text, re.DOTALL | re.IGNORECASE)
    if m:
        return m.group(1).strip().rstrip(";").strip()
    # Fallback: lấy từ SELECT/WITH đầu tiên, dừng trước ``` hoặc hết chuỗi
    m = re.search(r"(SELECT|WITH)\b.*?(?=\s*```|$)", text, re.DOTALL | re.IGNORECASE)
    return (m.group(0).strip().rstrip(";").strip() if m else "")