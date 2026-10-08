-- Sysadmin seed: IT + System Administrator (password: test@123, same bcrypt hash as other test accounts)
-- profile_pic_url: '' not NULL — cột là NOT NULL, NULL khiến script fail và seed không bao giờ chạy được
INSERT INTO public.users (user_id, annual_leave_days, birth_date, email, first_name, gender, joined_date, last_name, password, profile_pic_url, used_leave_days, department_id, job_id, face_embedding, employee_code, shift_id, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000099',
  12, '1990-01-01', 'sysadmin@company.com', 'Van Admin', 'Male', '2024-01-01', 'Nguyen',
  '$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa',
  '', 0,
  '0190abcd-1234-7def-89ab-cdef01234567',
  '0190abcd-7006-7def-89ab-cdef01234573',
  NULL, 'SYSADMIN',
  '52a5e36a-8fc5-4142-8d20-0a2436ab59a3',
  true
)
ON CONFLICT (email) DO NOTHING;
