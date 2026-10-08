-- Mở rộng CHECK constraint của user_permission_grants khi thêm PermissionKey mới.
-- Không có Flyway/Liquibase trong pom.xml và spring.jpa.hibernate.ddl-auto KHÔNG migrate được
-- CHECK constraint, nên phải chạy SQL tay. File này chạy tự động khi khởi tạo volume DB mới;
-- nếu volume đã tồn tại thì chạy tay:  psql -d hrm -f init-db/04_permission_keys.sql

ALTER TABLE public.user_permission_grants
    DROP CONSTRAINT IF EXISTS user_permission_grants_permission_check;

ALTER TABLE public.user_permission_grants
    ADD CONSTRAINT user_permission_grants_permission_check CHECK (permission::text = ANY (ARRAY[
        'ATTENDANCE_VIEW_ALL'::text,
        'LEAVE_VIEW_ALL'::text,
        'OVERTIME_VIEW_ALL'::text,
        'PAYROLL_VIEW_ALL'::text,
        'RESIGN_VIEW_ALL'::text,
        'LEAVE_APPROVE'::text,
        'OVERTIME_APPROVE'::text,
        'RESIGN_APPROVE'::text,
        'TIMESHEET_LOCK'::text,
        'PAYROLL_MANAGE'::text,
        'ATTENDANCE_VIEW_DEPT'::text,
        'LEAVE_VIEW_DEPT'::text,
        'OVERTIME_VIEW_DEPT'::text,
        'LEAVE_APPROVE_DEPT'::text,
        'OVERTIME_APPROVE_DEPT'::text,
        'EVALUATION_VIEW_ALL'::text,
        'EVALUATION_VIEW_DEPT'::text,
        'EVALUATION_APPROVE'::text,
        'EVALUATION_APPROVE_DEPT'::text,
        'ACCOUNT_LOCK'::text,
        'PERMISSION_GRANT'::text,
        'ORG_MANAGE'::text,
        'EMPLOYEE_VIEW_ALL'::text,
        'EMPLOYEE_EDIT'::text,
        'DOCUMENT_UPLOAD'::text,
        'VIEW_ASSETS'::text,
        'MANAGE_ASSETS'::text,
        'IT_TICKET_HANDLE'::text
    ]));
