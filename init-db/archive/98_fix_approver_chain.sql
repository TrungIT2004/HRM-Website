-- 98_fix_approver_chain.sql
-- Sua approver_id cho don nghi phep / tang ca theo dung chuoi phan cap:
--   Chairman  -> cap cao nhat, khong co nguoi duyet  -> NULL
--   Director  -> Chairman
--   VDD       -> Director
--   Truong phong -> Director
--   Nhan vien -> Truong phong cung phong ban
-- Idempotent: chay lai nhieu lan van ra cung ket qua.

BEGIN;

DROP TABLE IF EXISTS tmp_approver_map;
CREATE TEMP TABLE tmp_approver_map AS
SELECT
    u.user_id,
    CASE
        WHEN j.title = 'Chairman' THEN NULL
        WHEN j.title = 'Director'
            THEN (SELECT c.user_id FROM users c JOIN jobs cj ON cj.job_id = c.job_id
                  WHERE cj.title = 'Chairman' LIMIT 1)
        WHEN j.title LIKE 'Department Head%'
          OR j.title LIKE '%Deputy%'
          OR j.title LIKE '%Vice%'
            THEN (SELECT c.user_id FROM users c JOIN jobs cj ON cj.job_id = c.job_id
                  WHERE cj.title = 'Director' LIMIT 1)
        -- Truong phong: tim theo department_id, KHONG noi chuoi ten
        -- ("Department Head of IT" != "Department Head of " || 'Information Technology')
        ELSE (SELECT h.user_id FROM users h JOIN jobs hj ON hj.job_id = h.job_id
              WHERE h.department_id = u.department_id
                AND hj.title LIKE 'Department Head%' LIMIT 1)
    END AS approver_user_id
FROM users u
JOIN jobs j ON j.job_id = u.job_id;

UPDATE leave_requests lr
SET approver_id = m.approver_user_id, updated_at = now()
FROM tmp_approver_map m
WHERE m.user_id = lr.requestor_id;

UPDATE overtime_records ot
SET approver_id = m.approver_user_id
FROM tmp_approver_map m
WHERE m.user_id = ot.requestor_id;

DROP TABLE tmp_approver_map;

COMMIT;

-- Kiem tra: moi duong duoc dung cap, khong con tu duyet
SELECT 'leave' AS src, r.employee_code AS req_code, rj.title AS req_job,
       coalesce(a.employee_code, '(NULL)') AS appr_code, coalesce(aj.title, '-') AS appr_job
FROM leave_requests lr
JOIN users r       ON r.user_id = lr.requestor_id
LEFT JOIN jobs rj  ON rj.job_id = r.job_id
LEFT JOIN users a  ON a.user_id = lr.approver_id
LEFT JOIN jobs aj  ON aj.job_id = a.job_id
UNION ALL
SELECT 'ot', r.employee_code, rj.title, coalesce(a.employee_code,'(NULL)'), coalesce(aj.title,'-')
FROM overtime_records ot
JOIN users r       ON r.user_id = ot.requestor_id
LEFT JOIN jobs rj  ON rj.job_id = r.job_id
LEFT JOIN users a  ON a.user_id = ot.approver_id
LEFT JOIN jobs aj  ON aj.job_id = a.job_id
GROUP BY 1,2,3,4,5
ORDER BY 1,3,2;
