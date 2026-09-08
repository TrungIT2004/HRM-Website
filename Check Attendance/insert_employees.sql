SET client_encoding = 'UTF8';

-- Xóa user cũ nếu có
DELETE FROM users WHERE employee_code IN ('EMP021','EMP022','EMP023','EMP024','EMP025','EMP026');

-- 1. Tạo 6 user mới (có dấu)
INSERT INTO users (
    user_id,
    email,
    password,
    first_name,
    last_name,
    gender,
    birth_date,
    profile_pic_url,
    joined_date,
    annual_leave_days,
    used_leave_days,
    department_id,
    job_id,
    employee_code
)
VALUES
    (gen_random_uuid(), 'sales.employee@company.com', '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa', 'Nguyễn', 'Văn A', 'Male', '1990-01-15', '', '2024-06-01', 12, 0, (SELECT department_id FROM departments WHERE name = 'Sales'), (SELECT job_id FROM jobs WHERE title = 'Sales Executive'), 'EMP021'),
    (gen_random_uuid(), 'marketing.employee@company.com', '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa', 'Trần', 'Thị B', 'Female', '1992-03-20', '', '2024-06-15', 12, 0, (SELECT department_id FROM departments WHERE name = 'Marketing & Communication'), (SELECT job_id FROM jobs WHERE title = 'Marketing Specialist'), 'EMP022'),
    (gen_random_uuid(), 'hr.employee@company.com', '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa', 'Lê', 'Văn C', 'Male', '1988-07-10', '', '2024-07-01', 12, 0, (SELECT department_id FROM departments WHERE name = 'Human Resources'), (SELECT job_id FROM jobs WHERE title = 'HR Generalist'), 'EMP023'),
    (gen_random_uuid(), 'finance.employee@company.com', '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa', 'Phạm', 'Thị D', 'Female', '1991-11-05', '', '2024-07-15', 12, 0, (SELECT department_id FROM departments WHERE name = 'Finance & Accounting'), (SELECT job_id FROM jobs WHERE title = 'Accountant'), 'EMP024'),
    (gen_random_uuid(), 'support.employee@company.com', '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa', 'Hoàng', 'Văn E', 'Male', '1989-09-25', '', '2024-08-01', 12, 0, (SELECT department_id FROM departments WHERE name = 'Customer Support'), (SELECT job_id FROM jobs WHERE title = 'Customer Support Representative'), 'EMP025'),
    (gen_random_uuid(), 'it.employee@company.com', '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa', 'Đỗ', 'Thị F', 'Female', '1993-12-12', '', '2024-08-15', 12, 0, (SELECT department_id FROM departments WHERE name = 'IT'), (SELECT job_id FROM jobs WHERE title = 'Software Engineer'), 'EMP026');

-- 2. Tạo user_profiles
INSERT INTO user_profiles (
    user_id,
    phone_number,
    personal_email,
    place_of_birth,
    marital_status,
    nationality,
    citizen_id_number,
    social_insurance_number,
    tax_identification_number,
    social_insurance_start_date,
    emergency_contact_name,
    emergency_contact_phone
)
SELECT
    user_id,
    '0912345678',
    REPLACE(email, '@company.com', '@personal.com'),
    CASE employee_code
        WHEN 'EMP021' THEN 'Hà Nội'
        WHEN 'EMP022' THEN 'Đà Nẵng'
        WHEN 'EMP023' THEN 'Hồ Chí Minh'
        WHEN 'EMP024' THEN 'Hà Nội'
        WHEN 'EMP025' THEN 'Đà Nẵng'
        WHEN 'EMP026' THEN 'Hồ Chí Minh'
    END,
    'Married',
    'Vietnamese',
    '001' || LPAD(SUBSTRING(employee_code FROM 4)::INT::TEXT, 9, '0'),
    'SI' || LPAD(SUBSTRING(employee_code FROM 4)::INT::TEXT, 5, '0'),
    'TAX' || LPAD(SUBSTRING(employee_code FROM 4)::INT::TEXT, 5, '0'),
    ('2020-01-01'::DATE + (SUBSTRING(employee_code FROM 4)::INT * 30)),
    'Emergency Contact',
    '0912345679'
FROM users
WHERE employee_code IN ('EMP021','EMP022','EMP023','EMP024','EMP025','EMP026');

-- 3. Tạo user_bank_accounts
INSERT INTO user_bank_accounts (
    user_id,
    bank_name,
    bank_account_number
)
SELECT
    user_id,
    'Vietcombank',
    'VCB' || LPAD(SUBSTRING(employee_code FROM 4)::INT::TEXT, 8, '0')
FROM users
WHERE employee_code IN ('EMP021','EMP022','EMP023','EMP024','EMP025','EMP026');

-- 4. Tạo user_contracts
INSERT INTO user_contracts (
    user_id,
    contract_type,
    contract_start_date,
    contract_end_date,
    probation_end_date
)
SELECT
    user_id,
    'Fixed-term',
    ('2024-06-01'::DATE + (SUBSTRING(employee_code FROM 4)::INT * 30)),
    ('2025-06-01'::DATE + (SUBSTRING(employee_code FROM 4)::INT * 30)),
    ('2024-09-01'::DATE + (SUBSTRING(employee_code FROM 4)::INT * 30))
FROM users
WHERE employee_code IN ('EMP021','EMP022','EMP023','EMP024','EMP025','EMP026');

-- 5. Tạo salaries
INSERT INTO salaries (
    salary_id,
    user_id,
    base_salary,
    pay_frequency,
    work_days,
    start_date,
    end_date,
    is_active
)
SELECT
    gen_random_uuid(),
    user_id,
    15000000,
    'MONTHLY',
    22,
    ('2024-06-01'::DATE + (SUBSTRING(employee_code FROM 4)::INT * 30)),
    NULL,
    TRUE
FROM users
WHERE employee_code IN ('EMP021','EMP022','EMP023','EMP024','EMP025','EMP026');