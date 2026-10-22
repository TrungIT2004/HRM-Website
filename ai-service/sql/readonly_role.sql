-- =====================================================================
-- HRM AI Text-to-SQL: read-only role cho ai-service (chạy trên DB `hrm`)
-- Chạy 1 lần bằng user postgres (admin). Tool SQL của AI chỉ có quyền
-- đọc nên file này cần bạn tự chạy: psql -U postgres -d hrm -f readonly_role.sql
-- Đổi 'thay_mat_khau_manh_o_day' trước khi chạy.
-- =====================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hrm_ai_reader') THEN
        CREATE ROLE hrm_ai_reader WITH LOGIN PASSWORD '@Minhtrung1408';
    END IF;
END
$$;

-- Thu hồi mặc định rồi cấp lại tối thiểu (least privilege)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM hrm_ai_reader;
REVOKE ALL ON SCHEMA public FROM hrm_ai_reader;
GRANT CONNECT ON DATABASE hrm TO hrm_ai_reader;
GRANT USAGE ON SCHEMA public TO hrm_ai_reader;

-- users: trừ password, face_embedding, profile_pic_url
GRANT SELECT (user_id, email, first_name, last_name, gender, birth_date,
    joined_date, annual_leave_days, used_leave_days, employee_code,
    department_id, job_id, shift_id, is_active) ON users TO hrm_ai_reader;

-- attendances: trừ edited_by (id người sửa, không phải của mình)
GRANT SELECT (attendance_id, user_id, work_date, clock_in_time, clock_out_time,
    status, shift_id, is_edited, edited_reason, is_deleted)
    ON attendances TO hrm_ai_reader;

GRANT SELECT ON leave_requests TO hrm_ai_reader;
GRANT SELECT ON overtime_records TO hrm_ai_reader;
GRANT SELECT ON payrolls TO hrm_ai_reader;
GRANT SELECT ON salaries TO hrm_ai_reader;
GRANT SELECT ON holidays TO hrm_ai_reader;
GRANT SELECT ON work_shifts TO hrm_ai_reader;
GRANT SELECT ON work_shift_schedules TO hrm_ai_reader;
GRANT SELECT ON departments TO hrm_ai_reader;
GRANT SELECT ON jobs TO hrm_ai_reader;
GRANT SELECT ON resignation_requests TO hrm_ai_reader;
GRANT SELECT ON user_contracts TO hrm_ai_reader;

-- monthly_timesheets: trừ locked_by (id HR khóa sổ)
GRANT SELECT (timesheet_id, user_id, period_month, period_year,
    standard_working_days, actual_worked_days, actual_work_hours,
    late_count, total_late_minutes, early_departure_count, absent_days,
    paid_leave_days, unpaid_leave_days, total_actual_ot_hours,
    total_paid_ot_hours, ot_details, status, note, locked_at,
    created_at, updated_at) ON monthly_timesheets TO hrm_ai_reader;

-- user_bank_accounts: đọc toàn bộ (AI cần số TK của CHÍNH người hỏi để trả lời
-- "lương + ngân hàng của tôi"). Phạm vi cá nhân ép ở executor.validate_sql.
GRANT SELECT ON user_bank_accounts TO hrm_ai_reader;

-- user_profiles: trừ CCCD, BHXH, MST (định danh nhạy cảm)
GRANT SELECT (user_id, phone_number, personal_email, place_of_birth,
    nationality, marital_status, emergency_contact_name,
    emergency_contact_phone, social_insurance_start_date)
    ON user_profiles TO hrm_ai_reader;

-- user_permission_grants: trừ granted_by
GRANT SELECT (user_id, permission, granted_at)
    ON user_permission_grants TO hrm_ai_reader;

-- user_sessions: chỉ trạng thái, KHÔNG token/meta_data
GRANT SELECT (session_id, user_id, revoked, last_active_at, created_at, device_id)
    ON user_sessions TO hrm_ai_reader;

-- Performance: bảng gắn user (user_id/reviewee_id/reviewer_id)
GRANT SELECT ON performance_reviews TO hrm_ai_reader;
GRANT SELECT ON performance_scores TO hrm_ai_reader;

-- Assets: bảng gắn user (user_id) + bảng tra cứu (asset_categories, assets)
GRANT SELECT ON assets TO hrm_ai_reader;
GRANT SELECT ON asset_assignments TO hrm_ai_reader;
GRANT SELECT ON asset_categories TO hrm_ai_reader;
GRANT SELECT ON asset_images TO hrm_ai_reader;
GRANT SELECT ON asset_inventory_logs TO hrm_ai_reader;
GRANT SELECT ON asset_maintenances TO hrm_ai_reader;
GRANT SELECT ON asset_requests TO hrm_ai_reader;

-- IT Tickets: bảng gắn user (reporter_id, assignee_id)
GRANT SELECT ON it_tickets TO hrm_ai_reader;

-- KHÔNG cấp quyền (cố ý):
--   monthly_payroll_summaries (tổng toàn công ty, không gắn user_id)
--   pending_users             (người chưa onboard)
--   posts/comments/...        (mạng xã hội nội bộ, ngoài phạm vi giai đoạn 1)

-- Verify sau khi chạy: phải thấy 0 dòng (INSERT bị từ chối)
--   SET ROLE hrm_ai_reader; INSERT INTO users(email) VALUES('x'); -- ERROR
