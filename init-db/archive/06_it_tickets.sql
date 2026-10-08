-- IT Tickets V1 + tài sản cấp phòng ban.
-- Chạy 1 lần trên DB đã tồn tại:  psql -d hrm -f init-db/06_it_tickets.sql
-- (DB mới: Hibernate ddl-auto=update tự tạo bảng/cột; file này chỉ cần cho CHECK grants.)

-- 1. asset_assignments: user_id nullable + department_id (đồ dùng chung phòng ban)
ALTER TABLE public.asset_assignments ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE public.asset_assignments
    ADD COLUMN IF NOT EXISTS department_id uuid;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_assignment_department') THEN
        ALTER TABLE public.asset_assignments
            ADD CONSTRAINT fk_assignment_department FOREIGN KEY (department_id)
            REFERENCES public.departments (department_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_assignment_target') THEN
        ALTER TABLE public.asset_assignments
            ADD CONSTRAINT chk_assignment_target CHECK (num_nonnulls(user_id, department_id) = 1);
    END IF;
END $$;

-- 2. it_tickets (khớp entity ItTicket — ddl-auto=update sẽ no-op nếu đã có)
CREATE TABLE IF NOT EXISTS public.it_tickets (
    ticket_id uuid PRIMARY KEY,
    device_info TEXT NOT NULL,
    category VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location TEXT,
    image_url VARCHAR(255),
    priority VARCHAR(255) NOT NULL DEFAULT 'NORMAL',
    reporter_id uuid NOT NULL REFERENCES public.users (user_id),
    assignee_id uuid REFERENCES public.users (user_id),
    status VARCHAR(255) NOT NULL DEFAULT 'OPEN',
    resolve_note TEXT,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- 3. Mở CHECK grants cho key mới
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

-- 4. Cấp quyền xử lý IT ticket cho 3 IT (dovanhung, cuonghuuhoang46, it.employee) + SUPER_ADMIN
INSERT INTO public.user_permission_grants (user_id, permission, granted_by, granted_at) VALUES
    ('cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'IT_TICKET_HANDLE', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', '2026-01-05 08:00:00'),
    ('a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'IT_TICKET_HANDLE', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', '2026-01-05 08:00:00'),
    ('cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'IT_TICKET_HANDLE', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', '2026-01-05 08:00:00'),
    ('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c99', 'IT_TICKET_HANDLE', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', '2026-01-05 08:00:00')
ON CONFLICT (user_id, permission) DO NOTHING;

-- 5. Tài sản dùng chung phòng ban: Canon MF445dw (PR-0001) -> Human Resources
INSERT INTO public.asset_assignments
    (assignment_id, assigned_at, created_at, status, asset_id, assigned_by, user_id, department_id, notes)
VALUES
    (gen_random_uuid(), '2026-01-06 09:00:00', '2026-01-06 09:00:00', 'active',
     '9246d3d3-d820-416b-89e0-dd348dae3fcb', '35337165-e0d0-4dd1-9c67-cc48180363af', NULL,
     '0190abcd-4567-7def-89ab-cdef0123456a', 'Máy photo dùng chung P.Nhân sự');

UPDATE public.assets SET status = 'assigned', location = 'HCM - Toa A - Lau 3 - P.Nhân sự (dùng chung)'
WHERE asset_code = 'PR-0001';

-- Epson L3250 (PR-0004) -> Marketing & Communication (máy in dùng chung)
INSERT INTO public.asset_assignments
    (assignment_id, assigned_at, created_at, status, asset_id, assigned_by, user_id, department_id, notes)
VALUES
    (gen_random_uuid(), '2026-02-10 09:00:00', '2026-02-10 09:00:00', 'active',
     '283797f8-57c9-4620-9622-e458ed3b276a', '35337165-e0d0-4dd1-9c67-cc48180363af', NULL,
     '0190abcd-3456-7def-89ab-cdef01234569', 'Máy in màu dùng chung P.Marketing');

UPDATE public.assets SET status = 'assigned'
WHERE asset_code = 'PR-0004';

-- 6. Tickets 9 tháng đầu 2026 ( reporters: HR/Sales/MKT/Finance/CS; handlers: 3 IT )
-- Tháng 1
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy photo Canon P.Nhân sự', 'PRINTER', 'Kẹt giấy liên tục khay 2, đã thử tắt mở vẫn kẹt', 'P.Nhân sự - tầng 3', 'HIGH', '98d36266-d88a-4293-837f-a7750c2202a8', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Vệ sinh cụm sấy + thay bánh xe kéo giấy, in test 20 tờ ok', '2026-01-07 15:30:00', '2026-01-06 10:15:00', '2026-01-07 15:30:00'),
    (gen_random_uuid(), 'Laptop Dell Latitude cá nhân', 'LAPTOP_PC', 'Không vào được wifi công ty, báo No Internet dù đã nhập đúng pass', 'P.Sales - tầng 4', 'NORMAL', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Quên mạng cũ + nhập lại WPA2-Enterprise, kết nối lại bình thường', '2026-01-12 11:00:00', '2026-01-11 09:20:00', '2026-01-12 11:00:00'),
    (gen_random_uuid(), 'Email công ty', 'ACCOUNT_EMAIL', 'Quên mật khẩu email, bấm quên pass không nhận được mail reset', NULL, 'NORMAL', 'f3245dcc-970d-4986-8c36-6edc54a2f037', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Reset thủ công + bật MFA, user đăng nhập lại ok', '2026-01-15 14:00:00', '2026-01-14 16:40:00', '2026-01-15 14:00:00'),
    (gen_random_uuid(), 'Bàn phím Logitech K120', 'PERIPHERAL', 'Liệt 3 phím A S D, gõ lúc được lúc không', 'P.Kế toán - tầng 2', 'NORMAL', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Đổi bàn phím dự phòng kho IT, phím cũ thanh lý', '2026-01-20 10:00:00', '2026-01-19 08:30:00', '2026-01-20 10:00:00'),
    (gen_random_uuid(), 'Mạng LAN P.CSKH', 'NETWORK', 'Cả dãy 6 máy mất mạng từ sáng, đèn switch tắt', 'P.CSKH - tầng 4', 'HIGH', '9fbc67a0-b671-479c-9b46-3076df068741', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Nguồn switch lỏng, cắm lại + cố định dây, mạng lên lại', '2026-01-25 09:45:00', '2026-01-25 08:05:00', '2026-01-25 09:45:00');
-- Tháng 2
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy in màu Epson P.Marketing', 'PRINTER', 'In ra bị sọc ngang, màu xanh bị nhạt', 'P.Marketing - tầng 4', 'NORMAL', 'd02c2e04-26fe-49d6-89e2-7f5e72fc2cd3', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Clean đầu phun 2 lần + thay hộp mực cyan, in test ok', '2026-02-11 16:00:00', '2026-02-10 13:10:00', '2026-02-11 16:00:00'),
    (gen_random_uuid(), 'Laptop ThinkPad T14', 'SOFTWARE', 'Phần mềm kế toán MISA crash mỗi khi xuất báo cáo quý', 'P.Kế toán - tầng 2', 'HIGH', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Update MISA bản mới + tăng RAM ảo, xuất báo cáo ok', '2026-02-14 11:30:00', '2026-02-12 10:00:00', '2026-02-14 11:30:00'),
    (gen_random_uuid(), 'Wifi tầng 5 HN', 'NETWORK', 'Wifi chập chờn buổi chiều, họp online rớt liên tục', 'HN - Tòa B - tầng 5', 'HIGH', 'f3245dcc-970d-4986-8c36-6edc54a2f037', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Đổi kênh wifi 5GHz + reboot AP, đo lại ổn định', '2026-02-18 17:00:00', '2026-02-17 14:20:00', '2026-02-18 17:00:00'),
    (gen_random_uuid(), 'Màn hình Dell 24 inch', 'PERIPHERAL', 'Màn hình nhấp nháy, lúc lên lúc tắt', 'P.Sales - tầng 4', 'NORMAL', 'e6d9e525-11bf-4bd9-b284-f1b23e99b5dc', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Hỏng adapter nguồn, thay adapter kho IT', '2026-02-22 09:30:00', '2026-02-21 15:00:00', '2026-02-22 09:30:00'),
    (gen_random_uuid(), 'Máy chấm công vân tay', 'OTHER', 'Máy không nhận vân tay 3 nhân viên mới', 'Sảnh tầng 1', 'NORMAL', '947dba5a-ac2b-4cca-b66e-dad818a77ef1', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Đăng ký lại vân tay + lau mắt đọc, nhận đủ 3 người', '2026-02-27 10:00:00', '2026-02-26 09:00:00', '2026-02-27 10:00:00');
-- Tháng 3
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy photo Canon P.Nhân sự', 'PRINTER', 'Photo bị mờ một bên, scan cũng mờ theo', 'P.Nhân sự - tầng 3', 'NORMAL', '98d36266-d88a-4293-837f-a7750c2202a8', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Lau gương + kính scan, photo test rõ đều', '2026-03-05 14:00:00', '2026-03-04 11:00:00', '2026-03-05 14:00:00'),
    (gen_random_uuid(), 'VPN truy cập từ xa', 'NETWORK', 'Kết nối VPN báo lỗi xác thực dù user/pass đúng', 'Làm remote', 'HIGH', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Cert client hết hạn, cấp lại cert + hướng dẫn import', '2026-03-09 10:30:00', '2026-03-08 17:20:00', '2026-03-09 10:30:00'),
    (gen_random_uuid(), 'Laptop HP ProBook cá nhân', 'LAPTOP_PC', 'Máy nóng + quạt kêu to, hay tự tắt khi họp', 'P.Marketing - tầng 4', 'NORMAL', 'd02c2e04-26fe-49d6-89e2-7f5e72fc2cd3', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Vệ sinh quạt + tra keo tản nhiệt, chạy stress test 30p ok', '2026-03-15 16:00:00', '2026-03-13 09:40:00', '2026-03-15 16:00:00'),
    (gen_random_uuid(), 'Teams họp online', 'SOFTWARE', 'Share màn hình bị đen, người khác không thấy', 'P.Sales - tầng 4', 'NORMAL', 'e6d9e525-11bf-4bd9-b284-f1b23e99b5dc', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Tắt tăng tốc phần cứng GPU trong Teams, share lại ok', '2026-03-20 11:00:00', '2026-03-19 14:00:00', '2026-03-20 11:00:00'),
    (gen_random_uuid(), 'Chuột không dây', 'PERIPHERAL', 'Chuột lag, di chuyển giật cục', 'P.HR - tầng 3', 'NORMAL', '947dba5a-ac2b-4cca-b66e-dad818a77ef1', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Thay pin + đổi đầu thu sang cổng trước, hết lag', '2026-03-26 09:00:00', '2026-03-25 16:30:00', '2026-03-26 09:00:00');
-- Tháng 4
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy in HP P.Kế toán HN', 'PRINTER', 'Báo hết mực dù mới thay hộp mực mới', 'HN - Tòa B - tầng 2', 'NORMAL', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Reset chip mực + set lại loại giấy, máy nhận mực', '2026-04-08 10:00:00', '2026-04-07 13:30:00', '2026-04-08 10:00:00'),
    (gen_random_uuid(), 'Internet toàn chi nhánh HN', 'NETWORK', 'Mất internet toàn bộ từ 8h sáng', 'HN - Tòa B', 'HIGH', 'f3245dcc-970d-4986-8c36-6edc54a2f037', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Nhà mạng đứt cáp, chuyển sang line dự phòng 4G, 14h có lại', '2026-04-10 14:30:00', '2026-04-10 08:10:00', '2026-04-10 14:30:00'),
    (gen_random_uuid(), 'Tài khoản phần mềm CRM', 'ACCOUNT_EMAIL', 'Nhân viên mới chưa có tài khoản CRM để làm việc', 'P.Sales - tầng 4', 'NORMAL', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Tạo acc CRM + phân quyền sales, gửi thông tin đăng nhập', '2026-04-16 09:30:00', '2026-04-15 10:00:00', '2026-04-16 09:30:00'),
    (gen_random_uuid(), 'Laptop Dell cá nhân', 'LAPTOP_PC', 'Bàn phím liệt hàng số, phải dùng bàn phím ảo', 'P.CSKH - tầng 4', 'NORMAL', '9fbc67a0-b671-479c-9b46-3076df068741', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Thay bàn phím laptop (đặt linh kiện 3 ngày), lắp xong gõ ok', '2026-04-22 15:00:00', '2026-04-18 08:50:00', '2026-04-22 15:00:00'),
    (gen_random_uuid(), 'Máy chiếu phòng họp', 'OTHER', 'Máy chiếu mở không lên hình, đèn báo đỏ', 'Phòng họp tầng 3', 'HIGH', '98d36266-d88a-4293-837f-a7750c2202a8', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Bóng đèn hết giờ, thay bóng dự phòng, chiếu lại rõ', '2026-04-28 09:00:00', '2026-04-27 13:00:00', '2026-04-28 09:00:00');
-- Tháng 5
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy photo Canon P.Nhân sự', 'PRINTER', 'Hết mực giữa đợt in hợp đồng, cần thay gấp', 'P.Nhân sự - tầng 3', 'HIGH', '947dba5a-ac2b-4cca-b66e-dad818a77ef1', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Thay hộp mực mới + in test 10 tờ, bàn giao lại', '2026-05-06 11:00:00', '2026-05-06 09:00:00', '2026-05-06 11:00:00'),
    (gen_random_uuid(), 'Outlook gửi mail lỗi', 'ACCOUNT_EMAIL', 'Gửi mail có file đính kèm >10MB toàn báo lỗi', 'P.Marketing - tầng 4', 'NORMAL', 'd02c2e04-26fe-49d6-89e2-7f5e72fc2cd3', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Nâng giới hạn đính kèm + hướng dẫn nén file/dùng drive', '2026-05-12 14:00:00', '2026-05-11 10:30:00', '2026-05-12 14:00:00'),
    (gen_random_uuid(), 'Laptop Asus Vivobook', 'LAPTOP_PC', 'Pin chai còn 40%, sập nguồn khi rút sạc', 'P.Sales - tầng 4', 'NORMAL', 'e6d9e525-11bf-4bd9-b284-f1b23e99b5dc', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Thay pin mới chính hãng, test xả sạc 2 chu kỳ ok', '2026-05-19 16:00:00', '2026-05-16 09:10:00', '2026-05-19 16:00:00'),
    (gen_random_uuid(), 'Wifi phòng họp tầng 4', 'NETWORK', 'Vào phòng họp là mất wifi, ra ngoài lại có', 'Phòng họp tầng 4', 'NORMAL', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Thêm 1 AP trong phòng họp, phủ sóng lại full vạch', '2026-05-23 10:30:00', '2026-05-22 15:00:00', '2026-05-23 10:30:00'),
    (gen_random_uuid(), 'Phần mềm Photoshop', 'SOFTWARE', 'Cần cài Photoshop bản quyền cho designer mới', 'P.Marketing - tầng 4', 'NORMAL', 'f3245dcc-970d-4986-8c36-6edc54a2f037', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Cài + active license công ty, designer dùng ok', '2026-05-29 09:00:00', '2026-05-28 14:00:00', '2026-05-29 09:00:00');
-- Tháng 6
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy in Epson P.Marketing', 'PRINTER', 'Không kết nối wifi, máy tính không tìm thấy máy in', 'P.Marketing - tầng 4', 'NORMAL', 'd02c2e04-26fe-49d6-89e2-7f5e72fc2cd3', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Reset wifi máy in + cài lại driver, in test ok', '2026-06-04 11:00:00', '2026-06-03 10:20:00', '2026-06-04 11:00:00'),
    (gen_random_uuid(), 'Laptop Lenovo cá nhân', 'SOFTWARE', 'Windows báo active, màn hình đen góc phải', 'P.Kế toán - tầng 2', 'NORMAL', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Active lại key bản quyền công ty, hết thông báo', '2026-06-10 09:30:00', '2026-06-09 08:40:00', '2026-06-10 09:30:00'),
    (gen_random_uuid(), 'Hệ thống camera', 'OTHER', 'Camera kho không xem lại được, báo lỗi ổ cứng', 'Kho tầng 1', 'HIGH', '9fbc67a0-b671-479c-9b46-3076df068741', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Ổ cứng đầu ghi bad, thay ổ mới 2TB + format, ghi hình lại', '2026-06-16 15:00:00', '2026-06-15 09:00:00', '2026-06-16 15:00:00'),
    (gen_random_uuid(), 'Tai nghe meeting', 'PERIPHERAL', 'Tai nghe mic rè, họp online người khác nghe không rõ', 'P.Sales - tầng 4', 'NORMAL', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Đổi tai nghe mới kho IT, mic test rõ', '2026-06-22 10:00:00', '2026-06-21 14:30:00', '2026-06-22 10:00:00'),
    (gen_random_uuid(), 'Mạng dây P.HR', 'NETWORK', '2 máy bàn mất mạng dây, đã thử đổi dây vẫn không lên', 'P.Nhân sự - tầng 3', 'NORMAL', '98d36266-d88a-4293-837f-a7750c2202a8', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Port switch chết 2 cổng, chuyển sang cổng dự phòng', '2026-06-28 11:00:00', '2026-06-27 09:30:00', '2026-06-28 11:00:00');
-- Tháng 7
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy photo Canon P.Nhân sự', 'PRINTER', 'Scan gửi mail báo lỗi, không gửi được file', 'P.Nhân sự - tầng 3', 'NORMAL', '947dba5a-ac2b-4cca-b66e-dad818a77ef1', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Đổi pass mail scan trong máy photo (pass mail cũ hết hạn), test gửi ok', '2026-07-03 14:00:00', '2026-07-02 11:00:00', '2026-07-03 14:00:00'),
    (gen_random_uuid(), 'Laptop MacBook Air M1', 'LAPTOP_PC', 'Máy không nhận màn hình rời qua hub USB-C', 'P.Marketing - tầng 4', 'NORMAL', 'f3245dcc-970d-4986-8c36-6edc54a2f037', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Hub cũ không tương thích M1, đổi hub Ugreen 9-in-1, nhận đủ 4K', '2026-07-09 10:30:00', '2026-07-08 15:20:00', '2026-07-09 10:30:00'),
    (gen_random_uuid(), 'Ổ cứng di động', 'OTHER', 'Ổ cứng chứa dữ liệu kế toán cắm không nhận', 'P.Kế toán - tầng 2', 'HIGH', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Lỗi phân vùng do rút nóng, cứu 100% dữ liệu + dặn eject trước khi rút', '2026-07-15 16:00:00', '2026-07-14 08:30:00', '2026-07-15 16:00:00'),
    (gen_random_uuid(), 'Zalo OA + CRM', 'SOFTWARE', 'CRM không đồng bộ tin nhắn Zalo về 2 ngày nay', 'P.Sales - tầng 4', 'HIGH', 'e6d9e525-11bf-4bd9-b284-f1b23e99b5dc', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'CANCELLED', NULL, NULL, '2026-07-20 09:00:00', '2026-07-20 09:30:00'),
    (gen_random_uuid(), 'Bàn phím cơ', 'PERIPHERAL', 'Xin cấp thêm 1 bàn phím cơ cho nhân viên mới CSKH', 'P.CSKH - tầng 4', 'NORMAL', '9fbc67a0-b671-479c-9b46-3076df068741', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Xuất kho 1 phím cơ Dareu, bàn giao + ký nhận', '2026-07-26 10:00:00', '2026-07-25 14:00:00', '2026-07-26 10:00:00');
-- Tháng 8
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy in HP P.Kế toán HN', 'PRINTER', 'In 2 mặt bị ngược chiều giấy', 'HN - Tòa B - tầng 2', 'NORMAL', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Set lại khổ giấy A4 + hướng lật trong driver, in test đúng', '2026-08-05 11:00:00', '2026-08-04 10:00:00', '2026-08-05 11:00:00'),
    (gen_random_uuid(), 'Tài khoản Google Workspace', 'ACCOUNT_EMAIL', 'Nhân viên nghỉ việc cần thu hồi + chuyển mail cho trưởng phòng', 'P.Sales - tầng 4', 'NORMAL', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Suspend acc + delegate mail cho trưởng phòng, xong offboard', '2026-08-11 15:00:00', '2026-08-10 09:30:00', '2026-08-11 15:00:00'),
    (gen_random_uuid(), 'Laptop Dell Vostro', 'LAPTOP_PC', 'Ổ SSD đầy 95%, máy chậm rì', 'P.HR - tầng 3', 'NORMAL', '98d36266-d88a-4293-837f-a7750c2202a8', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'DONE', 'Dọn temp + chuyển dữ liệu sang D, trống thêm 60GB, máy nhanh lại', '2026-08-17 10:00:00', '2026-08-16 14:00:00', '2026-08-17 10:00:00'),
    (gen_random_uuid(), 'Switch + wifi kho', 'NETWORK', 'Kho không có wifi để kiểm kê bằng PDA', 'Kho tầng 1', 'NORMAL', '9fbc67a0-b671-479c-9b46-3076df068741', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'DONE', 'Kéo dây + gắn AP phụ trong kho, PDA kết nối ok', '2026-08-23 16:00:00', '2026-08-22 09:00:00', '2026-08-23 16:00:00'),
    (gen_random_uuid(), 'Máy photo Canon P.Nhân sự', 'PRINTER', 'Nhăn giấy khi photo A3', 'P.Nhân sự - tầng 3', 'NORMAL', '98d36266-d88a-4293-837f-a7750c2202a8', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Thay lô sấy A3, photo test 10 tờ phẳng đẹp', '2026-08-29 09:30:00', '2026-08-28 11:00:00', '2026-08-29 09:30:00');
-- Tháng 9 (tháng hiện tại: lẫn OPEN/IN_PROGRESS để test hàng chờ)
INSERT INTO public.it_tickets
    (ticket_id, device_info, category, description, location, priority, reporter_id, assignee_id, status, resolve_note, resolved_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'Máy lạnh phòng server', 'OTHER', 'Điều hòa phòng server chảy nước, nhiệt độ lên 32 độ', 'Phòng server tầng 3', 'HIGH', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'a2e3fd3a-72df-4fcb-9582-c097a0de5fde', 'IN_PROGRESS', NULL, NULL, '2026-09-02 08:15:00', '2026-09-02 09:00:00'),
    (gen_random_uuid(), 'Máy in Epson P.Marketing', 'PRINTER', 'Màu đỏ in ra thành cam, sai màu catalogue', 'P.Marketing - tầng 4', 'HIGH', 'd02c2e04-26fe-49d6-89e2-7f5e72fc2cd3', NULL, 'OPEN', NULL, NULL, '2026-09-03 10:00:00', '2026-09-03 10:00:00'),
    (gen_random_uuid(), 'Laptop HP EliteBook', 'LAPTOP_PC', 'Bật không lên nguồn, cắm sạc đèn không sáng', 'P.Sales - tầng 4', 'HIGH', 'e6d9e525-11bf-4bd9-b284-f1b23e99b5dc', NULL, 'OPEN', NULL, NULL, '2026-09-04 09:30:00', '2026-09-04 09:30:00'),
    (gen_random_uuid(), 'Mạng wifi tầng 4', 'NETWORK', 'Wifi chậm bất thường giờ cao điểm, speedtest còn 5Mbps', 'Tầng 4 - Tòa A', 'NORMAL', '07f0ee2c-1cb3-4e1b-842c-0a98c28e8de6', 'cb0bf52b-924d-4a02-bcde-af3cb2a371ff', 'IN_PROGRESS', NULL, NULL, '2026-09-05 14:00:00', '2026-09-05 14:20:00'),
    (gen_random_uuid(), 'Outlook không gửi được mail', 'ACCOUNT_EMAIL', 'Báo lỗi 0x8004010F, không gửi/nhận 2 ngày', 'P.Kế toán - tầng 2', 'NORMAL', '1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd', 'cf26d867-49f1-4c12-b35b-c79bfb2884fc', 'DONE', 'Rebuild profile Outlook + tạo lại OST, mail về đủ', '2026-09-06 11:00:00', '2026-09-05 08:45:00', '2026-09-06 11:00:00');
