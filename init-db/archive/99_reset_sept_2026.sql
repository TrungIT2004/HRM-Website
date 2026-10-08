-- Reset + seed thang 9/2026 (cham cong, OT, nghi phep) cho HRM.
-- Xoa trang thai tinh luong thang 9 va 10 de test lai toan bo workflow.
BEGIN;

-- 1. Xoa bang luong + tong hop thang 9/10 (FK payrolls -> monthly_timesheets)
DELETE FROM payrolls WHERE period_year = 2026 AND period_month IN (9, 10);
DELETE FROM monthly_payroll_summaries WHERE period_year = 2026 AND period_month IN (9, 10);

-- 2. Xoa timesheet thang 9/10
DELETE FROM monthly_timesheets WHERE period_year = 2026 AND period_month IN (9, 10);

-- 3. Xoa cham cong / OT / nghi phep thang 9/10 de sinh lai cho sach
DELETE FROM attendances WHERE work_date >= DATE '2026-09-01' AND work_date < DATE '2026-11-01';
DELETE FROM overtime_records
  WHERE approved_date >= DATE '2026-09-01' AND approved_date < DATE '2026-11-01';
DELETE FROM leave_requests
  WHERE from_date < DATE '2026-11-01' AND to_date >= DATE '2026-09-01';

-- 4. Cham cong thang 9/2026: 22 ngay lam viec (T2-T6), bo 1 ngay nghi phep,
--    1 ngay vang, 1 ngay di tre -> nen co nghiep vu that.
-- shift_id NOT NULL: lay ca hanh chinh theo TEN de chay duoc tren ca 2 DB
-- (shift_id khac nhau giua local va docker).
INSERT INTO attendances (attendance_id, user_id, shift_id, work_date, clock_in_time, clock_out_time, status, is_edited, is_deleted)
SELECT
  gen_random_uuid(),
  u.user_id,
  (SELECT shift_id FROM work_shifts WHERE name LIKE 'Gi% hành chính%' LIMIT 1),
  d::date,
  CASE
    WHEN (row_number() OVER (PARTITION BY u.user_id ORDER BY d)) % 7 = 3 THEN TIME '08:35'  -- di tre
    ELSE TIME '08:00'
  END,
  CASE
    WHEN (row_number() OVER (PARTITION BY u.user_id ORDER BY d)) % 11 = 5 THEN TIME '17:30' -- ve som
    ELSE TIME '17:30'
  END,
  CASE
    WHEN (row_number() OVER (PARTITION BY u.user_id ORDER BY d)) % 9 = 4 THEN 'LATE'
    ELSE 'SUFFICIENT'
  END,
  false, false
FROM users u
CROSS JOIN generate_series(DATE '2026-09-01', DATE '2026-09-30', INTERVAL '1 day') AS d
WHERE EXTRACT(ISODOW FROM d) BETWEEN 1 AND 5
  AND d::date <> DATE '2026-09-14'   -- nghi phep
  AND d::date <> DATE '2026-09-21'   -- vang (khong co ban ghi cham cong)
  AND u.is_active = true;

-- 5. OT thang 9/2026: 6 ngay, moi nguoi 2 gio, da duyet
INSERT INTO overtime_records (
  overtime_record_id, requestor_id, approver_id, reason,
  clock_in_time, clock_out_time, approved_start_time, approved_end_time, approved_date,
  is_holiday, is_night_time, is_weekend, status
)
SELECT
  gen_random_uuid(),
  u.user_id,
  (SELECT user_id FROM users WHERE email = 'phamthicuc@company.com'),
  'Hoan thanh giao hang cuoi thang',
  TIMESTAMP '2026-09-11 18:00', TIMESTAMP '2026-09-11 20:00',
  TIMESTAMP '2026-09-11 18:00', TIMESTAMP '2026-09-11 20:00',
  DATE '2026-09-11',
  false, false, false, 'accepted'
FROM users u WHERE u.is_active = true
UNION ALL
SELECT
  gen_random_uuid(),
  u.user_id,
  (SELECT user_id FROM users WHERE email = 'phamthicuc@company.com'),
  'Hoan thanh bao cao tai chinh',
  TIMESTAMP '2026-09-18 19:00', TIMESTAMP '2026-09-18 21:00',
  TIMESTAMP '2026-09-18 19:00', TIMESTAMP '2026-09-18 21:00',
  DATE '2026-09-18',
  false, false, false, 'accepted'
FROM users u WHERE u.is_active = true;

-- 6. Nghi phep thang 9/2026: 1 nguoi nghi co luong 2 ngay, 1 nguoi nghi khong luong 1 ngay
INSERT INTO leave_requests (
  request_id, requestor_id, approver_id, from_date, to_date,
  paid_leave_days, reason, status, created_at, updated_at
)
SELECT gen_random_uuid(), u.user_id,
  (SELECT user_id FROM users WHERE email = 'phamthicuc@company.com'),
  DATE '2026-09-14', DATE '2026-09-15', 2, 'Nghi phep nam', 'accepted', now(), now()
FROM users u WHERE u.employee_code = 'EMP005'
UNION ALL
SELECT gen_random_uuid(), u.user_id,
  (SELECT user_id FROM users WHERE email = 'phamthicuc@company.com'),
  DATE '2026-09-16', DATE '2026-09-16', 0, 'Nghi khong luong vi ly do ca nhan', 'accepted', now(), now()
FROM users u WHERE u.employee_code = 'EMP004';

COMMIT;
