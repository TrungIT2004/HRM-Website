# Kết quả test Generation — DB_ONLY (Text2SQL trên HRM DB)

## 1. E2E 200 câu trên seed thật (`generation/db_only/llm_200q_report.json`, 2026-10-10, 120b)

19 conversations, user ảo `hr.employee@company.com`, seed resignation/timesheet T9/2026 thật.

| Verdict | Số câu |
|---|---|
| PASS sạch | 176 |
| PASS ghi điều kiện / LIMIT đã biết (citation mù, ngày lễ, thiếu JD...) | 24 |
| FAIL | **0** |

## 1b. Chạy lại bằng gemma4:31b (2026-10-12, `eval_db_answer` + `eval_db_generation`, 187q)

| Metric | 120b | gemma |
|---|---|---|
| answer fact_recall | 0.775 | 0.764 |
| answer_ok | 0.631 | 0.605 |
| generation sql_ok | 0.9947 | 0.9786 |
| generation rows_match | 0.7005 | **0.8021** |
| generation latency | — | 1271ms |

Ngang nhau trong nhiễu (fact/answer/sql_ok lệch ≤0.026), rows_match khá hơn rõ.
Kết luận: gemma đủ thay 120b ở đường DB.

## 2. Unit Text2SQL (`generation/db_only/test_text2sql.py`)

Guard + router-parse + schema Registry, thuần túy không cần DB/LLM (1 test tự skip khi mất DB):
**38 passed**. Chạy: `py -m pytest tests/generation/db_only/test_text2sql.py -q`.

## 3. Tầng SQL/answer chi tiết (sống ở `retrieval_db_only/`)

* Projection SQL vs gold (`eval_db_generation.py`, 187q): sql_ok 0.9947 PASS / rows_match 0.7005 FAIL.
* Facts trong đáp án (`eval_db_answer.py`, 187q): fact_recall 0.7435 / answer_ok 0.5892 — xem
`retrieval_db_only/DB_RETRIEVAL_RESULTS.md` (kết luận: không gate bằng 2 số này, dùng sql_ok + spot-check).
