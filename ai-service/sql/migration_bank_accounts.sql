-- =====================================================================
-- Migration user_bank_accounts: 1 nhân viên nhiều tài khoản
--
-- Chạy 1 lần bằng user postgres (admin):
--   psql -U postgres -d hrm -f migration_bank_accounts.sql
--
-- Gồm:
--   1. Đổi PK user_id -> id (bỏ ràng buộc 1 tài khoản / 1 người)
--   2. Thêm bank_code, account_holder_name, is_default, created_at
--   3. Backfill 100 record: BIN theo ngân hàng, tên chủ TK = HỌ TÊN nhân viên
--   4. Partial unique index: mỗi user tối đa 1 tài khoản is_default
--   5. Grant SELECT toàn bộ cho hrm_ai_reader, xoá v_user_bank_masked
-- =====================================================================

BEGIN;

-- ─── 0. BỎ VIEW TRƯỚC ────────────────────────────────────────────────
-- Phải drop view trước: Postgres chặn ALTER/RENAME cột mà view phụ thuộc vào.
DROP VIEW IF EXISTS v_user_bank_masked;

-- ─── 1. Đổi PK: bỏ PK cũ (user_id), thêm cột id ────────────────────
ALTER TABLE user_bank_accounts DROP CONSTRAINT IF EXISTS user_bank_accounts_pkey;
ALTER TABLE user_bank_accounts ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();

-- Đổi tên cột cho khớp yêu cầu (account_number thay bank_account_number)
ALTER TABLE user_bank_accounts RENAME COLUMN bank_account_number TO account_number;

-- ─── 2. Thêm cột mới ─────────────────────────────────────────────────
ALTER TABLE user_bank_accounts ADD COLUMN IF NOT EXISTS bank_code           VARCHAR(50);
ALTER TABLE user_bank_accounts ADD COLUMN IF NOT EXISTS account_holder_name  VARCHAR(255);
ALTER TABLE user_bank_accounts ADD COLUMN IF NOT EXISTS is_default          BOOLEAN DEFAULT FALSE;
ALTER TABLE user_bank_accounts ADD COLUMN IF NOT EXISTS created_at
    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- account_number rút gọn 50 (không ép NOT NULL để không vỡ nếu có dòng NULL)
ALTER TABLE user_bank_accounts ALTER COLUMN account_number TYPE VARCHAR(50);

-- Điền id cho các dòng cũ trước khi set NOT NULL
UPDATE user_bank_accounts SET id = COALESCE(id, gen_random_uuid()) WHERE id IS NULL;
ALTER TABLE user_bank_accounts ALTER COLUMN id SET NOT NULL;

-- PK mới trên id (cho phép 1 user nhiều tài khoản)
ALTER TABLE user_bank_accounts ADD CONSTRAINT user_bank_accounts_pkey PRIMARY KEY (id);

-- UNIQUE(user_id, account_number): chặn trùng số TK cho cùng 1 người
ALTER TABLE user_bank_accounts DROP CONSTRAINT IF EXISTS user_bank_accounts_user_id_account_number_key;
ALTER TABLE user_bank_accounts ADD CONSTRAINT user_bank_accounts_user_id_account_number_key
    UNIQUE (user_id, account_number);

-- Mỗi user tối đa 1 tài khoản mặc định (quyết định tài khoản nhận lương)
CREATE UNIQUE INDEX IF NOT EXISTS ux_user_bank_accounts_one_default
    ON user_bank_accounts (user_id) WHERE is_default;

-- ─── 3. Backfill dữ liệu cho các record đang có ─────────────────────
-- BIN thật của các ngân hàng Việt Nam
UPDATE user_bank_accounts SET bank_code = '970436' WHERE bank_name ILIKE '%Vietcombank%' OR bank_name ILIKE 'VCB%';
UPDATE user_bank_accounts SET bank_code = '970407' WHERE bank_name ILIKE '%Techcombank%';
UPDATE user_bank_accounts SET bank_code = '970508' WHERE bank_name ILIKE 'ACB%';
UPDATE user_bank_accounts SET bank_code = '970437' WHERE bank_name ILIKE 'BIDV%';
UPDATE user_bank_accounts SET bank_code = '970418' WHERE bank_name ILIKE '%TPBank%';
UPDATE user_bank_accounts SET bank_code = '970426' WHERE bank_name ILIKE '%MB Bank%';
UPDATE user_bank_accounts SET bank_code = '970432' WHERE bank_name ILIKE '%VPBank%';
UPDATE user_bank_accounts SET bank_code = '970403' WHERE bank_name ILIKE '%Sacombank%';
UPDATE user_bank_accounts SET bank_code = '970466' WHERE bank_name ILIKE '%VietinBank%';
UPDATE user_bank_accounts SET bank_code = '970429' WHERE bank_name ILIKE '%Agribank%';
UPDATE user_bank_accounts SET bank_code = '970432' WHERE bank_code IS NULL;

-- Tên chủ tài khoản = HỌ + TÊN nhân viên, VIẾT HOA, giữ dấu
UPDATE user_bank_accounts b
SET account_holder_name = upper(trim(u.first_name || ' ' || u.last_name))
FROM users u
WHERE u.user_id = b.user_id
  AND b.account_holder_name IS NULL;

-- Mỗi nhân viên đang có 1 tài khoản -> đánh dấu mặc định.
-- Dùng "IS NOT TRUE" vì ADD COLUMN đã set DEFAULT FALSE cho dòng cũ (không NULL).
UPDATE user_bank_accounts SET is_default = TRUE WHERE is_default IS NOT TRUE;

-- Chuẩn hoá số tài khoản về 14 số: BIN(6) + 8 số ngẫu nhiên
-- Số cũ dạng 'ACC19036888999029' không phải số TK thật -> sinh lại.
-- hashtext cho số ngẫu nhiên ổn định (chạy lại vẫn ra số cũ).
-- Lưu ý: lpad nhận text -> phải cast sang text trước.
UPDATE user_bank_accounts
SET account_number = bank_code || lpad(
        (abs(hashtext(account_number || user_id::text)) % 100000000)::bigint::text,
        8, '0')
WHERE account_number !~ '^[0-9]{14}$' OR length(account_number) <> 14;

-- Trùng số sau khi sinh -> dồn bằng row_number
WITH ranked AS (
    SELECT id, row_number() OVER (
               PARTITION BY user_id, account_number
               ORDER BY user_id, created_at NULLS FIRST, id
           ) AS rn
    FROM user_bank_accounts
)
UPDATE user_bank_accounts b
SET account_number = b.account_number || '1'
FROM ranked
WHERE ranked.id = b.id AND ranked.rn > 1;

-- ─── 4. Grant ─────────────────────────────────────────────────────────
-- hrm_ai_reader được đọc TOÀN BỘ (không còn che số TK). View đã drop ở bước 0.
GRANT SELECT ON user_bank_accounts TO hrm_ai_reader;

COMMIT;

-- ─── Verify ───────────────────────────────────────────────────────────
SELECT count(*) AS total,
       count(*) FILTER (WHERE is_default) AS mac_dinh,
       count(*) FILTER (WHERE account_holder_name IS NULL) AS thieu_ten,
       count(*) FILTER (WHERE account_number !~ '^[0-9]{14}$') AS sai_dinh_dang
FROM user_bank_accounts;
