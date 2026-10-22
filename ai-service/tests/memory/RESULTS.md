# Kết quả test Memory rewrite — 50 conversations (đường prod)

**Ngày chạy:** 2026-10-11 (3 runs: 0.881 / 0.879 / 0.883 đường fallback; 0.854 / 0.863 đường prod)
**Dataset:** `memory/data/memory_dataset.csv` (1240 turns / 250 sessions, kiến thức chung QRECC — NGOÀI domain HR)
**Tool:** `memory/test_memory_sessions.py` → `memory/memory_rewrite_results.json` (từng câu + route)
**Cách đo:** top 50 session dài nhất, mỗi turn dùng gold history các turn trước, gọi đúng đường prod
`rewrite_and_route_step` (merged rewrite+route, 1 LLM call), chấm overlap từ ≥4 ký tự vs cột `rewrite`.

## Số chính (đường prod, run chốt)

| Metric | Giá trị |
|---|---|
| rewrite_score (mean 50 session) | **0.863** |
| turns chấm được (rewrite ≠ question) | 283 / 405 |
| llm_rewrote | 314 / 405 |
| route thực tế | OUT_OF_SCOPE 351 / DOC_ONLY 51 / DIRECTORY 3 |

Route OUT_OF_SCOPE áp đảo là đúng thiết kế (dataset ngoài nghiệp vụ HR).

## Lịch sử fix (đã verify từng câu)

1. Lần đầu đo nhầm đường fallback `condense_question` (gần như chết trên prod) — chuyển sang `rewrite_and_route_step`.
2. Luật tham chiếu thứ tự/danh sách + giữ tên riêng: thêm vào `CONDENSE_PROMPT` rồi port sang `REWRITE_ROUTE_PROMPT` (`src/sql/router.py`). Verify: `68t2 Madrid→Barcelona 0→1.0`, `226t9 0.2→0.8`.
3. Còn lại: tham chiếu mơ hồ 2 list cạnh tranh (`200t5`), tóm tắt list (`106t6`), nhiễu metric đếm chữ (~70% fail là paraphrase đúng bị phạt) — dừng, không đuổi.

## Bản cũ (tham chiếu)

15 conv full-path (tự ingest doc rồi hỏi): rewrite 0.888 / answer 0.921 / recall 0.963 / summary 15/15
(`_archive/TEST_RESULTS.md`, `_archive/memory_session_results.json`). Answer/recall là điểm ảo
(doc tự chế) — chỉ giữ rewrite làm tham chiếu.

## Chạy lại

```bash
cd ai-service
python tests/memory/test_memory_sessions.py
# Output: tests/memory/memory_rewrite_results.json
```
