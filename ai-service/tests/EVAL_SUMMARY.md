# Tổng hợp kết quả eval — ai-service (dữ liệu nội bộ)

> Phạm vi: CHỈ đánh giá trên dữ liệu nội bộ doanh nghiệp — corpus HR trong DB
> (BLLĐ 2019, quy chế quản trị Petrolimex/EVNFinance/MWG, quy trình VPP-mực in,
> quy chế lương mẫu, điều phối xe ACT, payrolls mẫu) + DB nghiệp vụ HRM (seed test)
> + câu hỏi HR. Loại trừ: HotpotQA, ViQuAD, QRECC/memory_dataset (kiến thức chung
> ngoài domain — xem `_archive/EVAL_RESULTS.md`, `_archive/VIQUAD_EVAL_RESULTS.md`, `_archive/TEST_RESULTS.md`
> nếu cần).
>
> Số chi tiết từng câu nằm ở file nguồn cột `Nguồn` (đường dẫn tính từ `tests/`). Ngày là ngày chạy thực tế.

## 1. Bảng tổng (đọc 1 phút)

| Mảng | Metric chính | Ngày chạy | Nguồn |
|---|---|---|---|
| Retrieval DB_ONLY (187q, user ảo seed thật) | route_acc 0.963, sql_ok 0.984–0.995, non_empty 0.984 | 2026-10-07 | `retrieval_db_only/DB_RETRIEVAL_RESULTS.md` |
| Retrieval DOC_ONLY nội bộ (146q→113q, từ `generated_testset.csv`) | Hit@5 100%, MRR 0.99; fallback 0% @T0.15 → **58% @T0.64** | 2026-10-07 / rerun 2026-10-11 | `retrieval_doc_only/RETRIEVAL_DOC_ONLY_RESULTS.md` |
| Routing LLM (361q HR) | 89.8% (DB 92.8 / DOC 87.8 / HYB 85.7) | 2026-10-07 | `routing/LLM_ROUTING_TEST_RESULTS.md` |
| Routing keyword (180q) | 90.0% | 2026-10-07 | `routing/LLM_ROUTING_TEST_RESULTS.md` |
| Routing DIRECTORY | 30+ checks ALL PASS, e2e 4/4 | 2026-10-07 | `routing/LLM_ROUTING_TEST_RESULTS.md` |
| Threshold từ chối (30 âm + 5 dương, corpus nội bộ) | **T=0.64**: chặn 30/30, oan 0/5 | 2026-10-11 | `retrieval_doc_only/threshold_calib_results.json` |
| Generation DB/Text2SQL (200q, 19 conv, seed HRM thật) | 176 PASS sạch + 24 PASS điều kiện, 0 FAIL | 2026-10-10 | `generation/db_only/RESULTS.md` |
| Generation RAG nội bộ (review 100q xe/VPP/lương/quản trị) | Chờ review tay, chưa verdict | — | `generation/doc_only/RESULTS.md` |
| Đáp án multi-turn nội bộ (30 conv × 12 turns, user seed thật, gemma) | Từ chối 71% câu legit; DOC đáp được overlap TB 0.63; p50 3.3s/p95 6.3s; **rò SĐT qua danh bạ** | 2026-10-12 | `memory/internal/RESULTS.md` |
| Hiệu năng retrieve+rerank (trên chunks nội bộ) | 16000ms → 825ms (**19x**) | 2026-09-30 | `_archive/TEST_RESULTS.md` |

## 2. Retrieval nội bộ

**DB_ONLY** (`retrieval_db_only/`, user Đặng Thanh Khải seed asset/ticket T1–T9/2026):
route_acc 0.9626 / sql_ok 0.984 / non_empty 0.984 (vượt ngưỡng 0.85/0.80). 3 fail đã mổ:
ngày EPOCH sai hàm, 2 câu "ai duyệt?" bị guard chặn JOIN `users` (đúng luật bảo mật —
đã fix app-side resolve tên qua query cố định). Chi tiết: `DB_RETRIEVAL_RESULTS.md`.

**DOC_ONLY** (`retrieval_doc_only/`, 146 câu sinh từ chính corpus):
Hit@5=100%, MRR 0.98–0.99. Rerun 113q ở T=0.64: top1_mean 0.606, fallback 58% (FAIL gate <20%).
Tối ưu đi kèm: cột `tsv` + GIN (SQL 4039ms→177ms, 23x), reranker fp16 (3.4x).

## 3. Routing (câu hỏi HR)

* LLM primary + keyword fallback. Lỗi tập trung ở over-classify `OUT_OF_SCOPE` (26/37) và biên HYBRID↔DB_ONLY (7). Latency ~2.1s/câu, bottleneck là LLM.
* Nhánh DIRECTORY (SĐT/ca/trạng thái nhân viên khác + self-anchor "của tôi"): 30+ checks pass, keyword giữ 92.8% (205/221), e2e 4/4. Defer: follow-up đa lượt, test live nhánh stream.

## 4. Threshold từ chối (`RELEVANCE_THRESHOLD = 0.76`, `SOFT = 0.50`, `chat_service.py`)

> Update 2026-10-15: đổi embedder sang `google/embeddinggemma-300m` (`.env`) làm thang
> điểm dịch chuyển → calib lại (`test_threshold_calib.py`): **T=0.76 chặn 30/30 âm,
> 0/5 dương**. 27 câu legit từng bị từ chối oan (bkai top1 <0.50) nay đạt 0.63–0.82,
> đều được đáp (LOW nếu <0.76). Quy tắc: **đổi embedder/corpus → calib lại ngưỡng**.

* Calib trên đúng corpus nội bộ: 30 câu âm (ngoài domain / kề HR nhưng tài liệu không có / bẫy từ khóa dùng từ trong corpus) + 5 câu dương BLLĐ. Âm max top1 0.627, dương min 0.674 → gap sạch.
* Verify sau khóa: 30/30 từ chối, 5/5 giữ; 6 câu bịa từng lọt `semantic_cache` đã xóa, cache về 0.
* ⚠️ Gap mỏng + mẫu dương 5 câu — **đo lại khi thêm/xóa tài liệu**.
  Rerun retrieval 113q ở T=0.64 cho fallback 58%: phân bố câu âm (max 0.627) và câu legit
  (p25 0.517) chồng nhau — không có ngưỡng vừa chặn hết bẫy vừa không oan. Giữ 0.64 =
  chọn an toàn; hạ ngưỡng chỉ khi chấp nhận hallucination trở lại.

## 5. Generation

* **DB/Text2SQL** (`generation/db_only/`): 200q E2E 176 PASS sạch + 24 PASS điều kiện, 0 FAIL;
  unit guard/router/schema 38 passed; projection SQL vs gold sql_ok 0.9947 (rows_match 0.70
  chỉ để soi). Latency có sẵn trong json (p50 6.9s) — cộng trung bình là đủ, khỏi đo riêng.
  Chi tiết: `generation/db_only/RESULTS.md`, `retrieval_db_only/DB_RETRIEVAL_RESULTS.md`.
* **RAG trên tài liệu nội bộ** (`generation/doc_only/`): RAGAS judge gpt-oss false-negative có hệ
  thống (faith ~0.52 dù audit tay 0/6 hallucination) — không gate bằng nó; review_100/30/70
  chờ verdict tay. Chi tiết: `generation/doc_only/RESULTS.md`, `retrieval_doc_only/GENERATION_DOC_RESULTS.md`.

## 6. Ngoài phạm vi file này (dataset ngoài, đã loại trừ)

* Memory rewrite 50 conv (`memory/memory_rewrite_results.json`, 0.863 đường prod, chi tiết `memory/RESULTS.md`) và bản cũ 15 conv (`_archive/TEST_RESULTS.md`): dataset QRECC kiến thức chung, KHÔNG phải dữ liệu nội bộ — giữ làm eval năng lực hội thoại, không tính vào chất lượng trên corpus doanh nghiệp.
* HotpotQA/ViQuAD: tương tự, xem `_archive/EVAL_RESULTS.md` / `_archive/VIQUAD_EVAL_RESULTS.md`.

## 7. Chạy lại (từ `ai-service/`)

```bash
python tests/retrieval_db_only/seed_db_eval.py            # seed DB (1 lần)
python tests/retrieval_db_only/eval_db_retrieval.py --n 187
python tests/retrieval_db_only/eval_db_generation.py --n 187
python tests/retrieval_db_only/eval_db_answer.py --n 187
python tests/retrieval_doc_only/eval_retrieval.py --n 146 --reuse
python tests/retrieval_doc_only/test_threshold_calib.py
python tests/memory/test_memory_sessions.py
py -m pytest tests/generation/db_only/test_text2sql.py -q
python tests/generation/doc_only/eval_ragas_full.py --n 30
```

## 8. Nợ có trigger

* Faithfulness khi có tài liệu, PBAC rò rỉ phòng ban (corpus hiện toàn `ALL`), gate CI — làm khi mở user thật / có tài liệu phân quyền.
* Re-review `generation/doc_only/review_100.json` gán verdict trước khi cần số generation RAG.

## 10. So sánh 120b vs gemma4:31b (chạy lại full khi đổi LLM, 2026-10-12; baseline 120b ở `tests/baselines-120b/`)

| Test | 120b | gemma | Kết luận |
|---|---|---|---|
| Routing 361→402q | 89.8%, 2087ms | **95.3%**, 933ms | Đổi, nhanh hơn 2.2x |
| Memory rewrite nội bộ 360 turns | 0.348 | **0.390**, route sạch hơn | Đổi |
| DB answer (187q) | 0.775 / 0.631 | 0.764 / 0.605 | Ngang (nhiễu) |
| DB generation (187q) | sql 0.9947, rows 0.7005 | sql 0.9786, rows **0.8021** | Ngang, rows khá hơn |
| Threshold 35q | 30/30 + 0/5 @0.64 | 30/30 + 0/5 @0.64 | Giữ 0.64 |
| pytest + drill | pass | pass, hành vi y hệt | OK |
| Latency DOC | ~6s/turn | **~3.5s**/turn | Đổi |
| Generation DOC verdicts | đáp án 120b (review_100) | đáp án mới ở `generation/doc_only/ragas_eval_gemma.json` (100q, chờ chấm tay) | Chấm rồi chốt |

Code hỗ trợ 2 model (`OLLAMA_FAST_MODEL` cho rewrite+route, `OLLAMA_MODEL` cho còn lại);
đổi main sang gemma = set `OLLAMA_MODEL=gemma4:31b`, rollback 1 dòng.

## 9. Vận hành pre-prod (chi tiết: `tests/latency/`, `tests/tokens/`, `tests/stress/`)

* **Token/turn (log usage provider thật)**: DOC ~3 calls ≈ **5.4k in / 0.45k out**;
  DB ~4 calls ≈ **16.5k in / 0.8k out**. Đầu tốn nhất: schema + few-shots text2sql.
  KHÔNG cắt schema (thí nghiệm cũ: prompt ngắn → SQL tệ + retry ×2.5).
  Từ giờ 4 script generation/retrieval-db (`eval_ragas_full`, `eval_db_retrieval`,
  `eval_db_generation`, `eval_db_answer`) ghi sẵn `elapsed` + `prompt_tokens` /
  `completion_tokens` / `llm_calls` từng row — cộng trung bình là ra latency +
  cost mà không chạy test riêng.
* **Breakdown/turn** (spy, không sửa prod; rerank nằm trong retrieve):
  DOC đáp được ≈ rewrite_route 1.3–2.5s + retrieve 1.2–3.0s (rerank 0.6–1.1, embed ~0.03,
  cache_check ~0.02) + llm_answer 2.3–2.6s = **5–8s**; câu bị từ chối ≈ 2.4–3s
  (bỏ qua call sinh đáp án); DB + text2sql 1–2s. Cache-hit ≈ 1.8s
  (vẫn tốn rewrite 1.1s — muốn rẻ nữa thì check cache trước rewrite).
* **Prefill/decode**: không đo được — API OpenAI-compatible không trả timing;
  thử stream thì server dồn token cuối mới xả (TTFT = total), không tách được.
* **LLM chết**: 5/5 HTTP 200, fallback đúng, injection vẫn chặn. Đã thêm `timeout=60`
  cả 2 client + log usage; drill lại giữ nguyên.
* **Concurrent (uvicorn workers=1)**: 3×15 req wall 64s vs 10×15 req wall 72s —
  parallelism hiệu dụng ≈ 1. Đo stage dưới tải (`latency/load_breakdown.py`):
  LLM phồng 1.4x, retrieve/rerank phẳng, DB pool OK, không rate limit app.
  Kết luận ngược dự đoán cũ: **cloud bóp concurrent trên calls lớn**
  (probe 5 calls nhỏ thì overlap tốt), GPU/DB được minh oan. workers=2 trên máy
  dev 6GB VRAM tệ hơn (thrash). Fix đúng: tune workers trên máy giống prod,
  hoặc giảm concurrent về phía provider (prompt ngắn, model nhẹ cho rewrite).
