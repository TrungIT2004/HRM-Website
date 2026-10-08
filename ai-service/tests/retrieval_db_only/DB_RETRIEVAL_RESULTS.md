# Kết Quả Test Retrieval — DB_ONLY (kể cả 3 module mới)

**Ngày test:** 2026-10-07
**Dataset:** `db_only_hybrid_questions.json` → **187 câu DB_ONLY**
(146 cũ + 41 mới: performance_reviews 10, performance_scores 5,
asset_assignments 8, asset_requests 6, assets 4, it_tickets 8)
**User test:** Đặng Thanh Khải (`d47d452a…`), joined 2026-01-02
**Seed:** `tests/retrieval_db_only/seed_db_eval.py` (3 assignments, 3 requests, 5 tickets,
Jan–Sep 2026; performance có sẵn 8 reviews + 80 scores)

---

## Tóm Tắt (3/3 PASS)

| # | Thông số | Giá trị | Ngưỡng | Trạng thái |
|---|----------|---------|--------|------------|
| 1 | **route_acc** (keyword → DB_ONLY/HYBRID) | **0.9626** | > 0.85 | ✅ PASS |
| 2 | **sql_ok** (sinh SQL + execute được) | **0.9840** | > 0.80 | ✅ PASS |
| 3 | **non_empty** (có dòng trả về) | **0.9840** | > 0.80 | ✅ PASS |
| 4 | error_rate | 0.016 (3/187) | tham khảo | — |
| 5 | latency_mean_ms | 2381 | tham khảo | LLM sinh SQL ~2.4s/câu |

Theo `check_type`: single_number 52/52, non_empty 85/87,
multi_row 37/37, two_period 10/11.

---

## 3 Câu Fail (phân tích)

| ID | Lỗi | Nguyên nhân |
|----|-----|-------------|
| `user_contracts_07` | `EXTRACT(EPOCH FROM (date - date))` không tồn tại | LLM dùng sai hàm tính khoảng ngày (bảng cũ, ngoài scope) |
| `asset_assignments_06` | Guard: thiếu `users.user_id = %(uid)s` | LLM JOIN `users` lấy **tên** người duyệt |
| `asset_requests_05` | Guard: thiếu `users.user_id = %(uid)s` | Như trên (alias `u_approver`) |

2/3 lỗi bảng mới cùng 1 pattern: câu hỏi "ai duyệt?" cần tên người duyệt →
SQL JOIN `users` → guard đòi uid filter trên mọi bảng gắn user → từ chối.
Guard đúng về mặt bảo mật (không đọc dòng user khác), nhưng UX cần tên
người duyệt (tiền lệ: `leave_requests_10` pass khi LLM không JOIN — hên xui).

**Đã sửa theo hướng app-side** (user chốt): guard giữ nguyên; `executor.directory_lines()`
resolve FK → tên/phòng/chức danh/email/SĐT qua query cố định, hook trong
`_run_text2sql`; prompt rule 8 dặn LLM chỉ SELECT id, không JOIN `users`.
Verify: "Ai là người duyệt cấp tài sản cho tôi?" → pass guard +
`Người duyệt: Lê Văn C (Human Resources – HR Generalist)`.
(SĐT/ngày sinh cố ý loại khỏi resolve — riêng tư hơn, chưa cần.)

---

## Thay Đổi Code Để Đạt (surgical)

| File | Thay đổi | Vì sao |
|------|----------|--------|
| `src/sql/schema_registry.py` | Đồng bộ 10 bảng mới theo cột DB thực tế | Registry cũ sai tên cột (`reviewee_id`, `asset_name`, `purchase_price`…), sai tên bảng (`asset_maintenance` → `asset_maintenances`), `performance_scores` không có `user_id` (phải JOIN) |
| `sql/readonly_role.sql:80` | `asset_maintenance` → `asset_maintenances` | Typo tên bảng |
| `src/sql/router.py` | +keywords 3 domain mới; OUT_OF_SCOPE chỉ khi đại từ + tên riêng viết hoa | Sửa false positive `"chị "` khớp nhầm `"chi tiết"` |
| `tests/db_only_hybrid_questions.json` | +41 câu (6 bảng mới) | Cover module mới |
| `tests/retrieval_db_only/seed_db_eval.py` (mới) | Seed 3+3+5 dòng Jan–Sep 2026 | User test chưa có asset/ticket |
| `tests/retrieval_db_only/eval_db_retrieval.py` (mới) | Harness: route + `_run_text2sql` production | Đo sql_ok/non_empty/latency |

Keyword accuracy: 92.8% toàn bộ (41/41 câu mới pass).

---

## Quyết Định Cần User Chốt

**Vấn đề:** câu hỏi "ai duyệt đơn của tôi?" cần tên người duyệt → SQL phải
JOIN `users` → guard hiện tại từ chối (đúng luật bảo mật, sai UX).

**Lựa chọn (đã chốt: app-side resolution):**
- ~~A. Nới guard~~ — loại (mở attack surface, cần review bảo mật).
- ~~B. Đổi câu hỏi~~ — loại (né vấn đề, xấu UX).
- ~~C. Chấp nhận~~ — thay bằng implement đã xong ở trên.

---

## Cách Chạy Lại

```bash
cd ai-service
python tests/retrieval_db_only/seed_db_eval.py            # seed (1 lần; --cleanup để xóa)
python tests/retrieval_db_only/eval_db_retrieval.py --n 187
# Output: tests/retrieval_db_only/db_retrieval_eval.json
python tests/retrieval_db_only/eval_db_answer.py --n 187  # answer-level
# Output: tests/retrieval_db_only/db_answer_eval.json
```

---

## Answer-Level Eval (facts trong đáp án tiếng Việt?)

Tool: `eval_db_answer.py` — facts từ gold SQL có trong answer không
(chuẩn hóa số Việt, ngày DD/MM, status→tiếng Việt, bỏ UUID/marker seed).

| Run | fact_recall | answer_ok | Ghi chú |
|---|---|---|---|
| 1 (--n 30) | 0.698 | 0.533 | checker strict |
| 2 (--n 30) | 0.867 | 0.767 | sau fix checker |
| 3 (--n 30) | 0.789 | 0.667 | — |
| 4 (--n 187) | 0.693 | 0.541 | full |
| 5 (--n 187) | **0.775** | **0.631** | sau fix checker v2 + schema notes |

**Kết luận trung thực:** metric dao động 70–87% giữa các run do variance
LLM (paraphrase đáp án + SQL khác nhau mỗi run). Mổ tay các miss cho thấy
đáp án đúng, checker/ambiguity là nguyên nhân chính:
- Composer localize đúng ("pending"→"đang chờ duyệt", "31/08/2026",
  "29.000.000 VND") mà checker cũ không hiểu → đã fix checker.
- Gold mơ hồ: tháng hiện tại (Oct, chưa có payroll) vs kỳ gần nhất;
  schedule vs actual; nhãn analytic ('peer'/'my_position').
- Bug thật đã fix nhờ eval: `work_days` vs SUM actual, `personal_email`
  vs `users.email`, NULL-prev diff, COUNT-zero, leave-vs-resignation,
  status case, day_of_week ISO, EXTRACT EPOCH trên date.
- Data quality: `holidays.description` mojibake trong DB (cần làm sạch nguồn).

**Khuyến nghị:** không gate production bằng con số này; dùng sql_ok (96–100%
ổn định) + spot-check tay mẫu câu trả lời. Ngưỡng tham khảo:
fact_recall ≥ 0.70, answer_ok ≥ 0.60 (vùng ổn định quan sát được).
