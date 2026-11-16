# Kết quả test Generation — DOC_ONLY (đáp án từ tài liệu nội bộ)

## 1. RAGAS 30 câu (`eval_ragas_full.py`, judge gpt-oss, 3 runs — xem `retrieval_doc_only/GENERATION_DOC_RESULTS.md`)

| Metric | Run 2 | Run 3 | Ngưỡng | Đạt? |
|---|---|---|---|---|
| faithfulness | 0.54 | 0.52 | ≥ 0.8 | ❌ |
| answer_relevancy | 0.38 | 0.40 | ≥ 0.8 | ❌ |
| context_precision | 0.54 | 0.56 | ≥ 0.7 | ❌ |
| context_recall | 0.47 | 0.53 | ≥ 0.7 | ❌ |

**Verdict đã audit tay: số thấp do JUDGE, không phải hệ thống.** 6 câu faithfulness==0 persistent
đều có đáp án đúng/có căn cứ (judge chấm 0 có hệ thống trên corpus OCR/table tiếng Việt;
bằng chứng mâu thuẫn: 1 câu context_precision=1.0 mà faithfulness=0.0). Tỉ lệ hallucination
thật trên mẫu audit: 0/6 rõ ràng. **Không gate production bằng RAGAS + gpt-oss**; gate bằng
retrieval metrics + refusal đúng chỗ + spot-check tay. Muốn số tự động: đổi judge hoặc goldens
do người review (`answer_draft` hiện là nháp LLM).

## 2. Hàng chờ review tay (chưa verdict, chưa làm gate được)

* `generation/doc_only/review_100.json` (100q: xe, VPP, lương, quản trị), `review_30_manual.json`,
  `review_70_extra.json`, `draft_golds_batch1.json`.
* `generation/doc_only/ragas_eval_gemma.json` (2026-10-12): regen 100 đáp án bằng
  **gemma** (no-judge, ~4.7k tokens/câu, 50 câu HIGH/MEDIUM) — review trên file này
  khi đổi LLM chính, đừng chấm đáp án 120b cũ.
* `generation/doc_only/review_100_gemma.json`: bản gọn 100 items
  (question + answer + 3 contexts cắt 400 chữ + `verdict: null`) — điền true/false
  vào đó. Số từ file gemma: **latency p50 7.7s / mean 8.5s, tokens ~4.7k/câu**.
* RAGAS batch lẻ (`ragas_eval_batch*.json`, `ragas_eval_rerun*.json`, `ragas_eval_100.json`):
  chạy thử bằng 120b, chưa điểm tổng.

## 3. Judge gemma4:31b 100 câu (`judge_gemma.py`, 2026-10-15, full contexts)

45/100 PASS groundedness trên `ragas_eval_gemma_judged.json` (judge thấy 3 contexts/câu,
temperature 0). Trong 55 FAIL: ~30 từ chối oan (đáp án "không có thông tin" nhưng
3 contexts có đáp án — di chứng của T=0.64 thiên an toàn), ~25 nghi bịa thêm chi tiết.

⚠️ Judge chỉ thấy top-3 trong khi đáp án sinh từ top-7 (vd ID=77 trích [TÀI LIỆU 5],
ID=70 trích [TÀI LIỆU 4]) — một phần FAIL nhóm "bịa" có thể oan. Muốn số thật:
chấm lại FAILs với đủ 7 contexts lúc sinh đáp án.

## 4. Re-judge 55 FAIL với rewrite + top-7 (`rejudge7.py`, 2026-10-15)

Tái hiện đúng evidence đường sinh đáp án (`_retrieve_lazy`: condense lại + retrieve
rewrite/alt gốc/top-7, temp 0 cùng model). **22/55 flip → True** (vd ID=8, 13, 70).
Tổng: **67/100** có căn cứ hoặc từ chối đúng. File: `ragas_eval_gemma_rejudge7.json`.

33 câu còn FAIL: **29 từ chối oan** (evidence có trong top-7 nhưng generator vẫn từ
chối — bệnh bảo thủ thật, cùng gốc với T=0.64) + 4 artifact đã mổ tay:
ID=5 đáp án chép đúng Điều 3 EVNFinance (verify trực tiếp bằng SQL chunk 4 —
retrieval không lôi được chunk này cho câu hỏi mơ hồ, không phải bịa);
ID=15 cùng pattern; ID=77 nội dung đúng ở [TÀI LIỆU 1], chỉ lệch số thứ tự trích
dẫn (số TÀI LIỆU giữa 2 lần retrieve khác nhau nên không so được citation index);
ID=98 từ chối sai giá Casio có trong corpus. **Hallucination thật xác nhận: 0.**

Caveat: rewrite condense lại (không lưu lúc eval) nên evidence là xấp xỉ; judge là
LLM nên 4 artifact chỉ mới spot-check tay, chưa đọc hết 33.

## 5. Fix 29 từ chối oan: nâng RELEVANCE_THRESHOLD 0.66 → 0.76 (2026-10-15)

Nguyên nhân thật không phải generator bảo thủ mà là **đổi embedder** (`.env`:
`LOCAL_EMBEDDING_MODEL=google/embeddinggemma-300m`, thay bkai; vectors đã re-embed)
làm thang điểm dịch chuyển: 27 câu oan (bkai top1 <0.50) nay đạt 0.63–0.82.
Calib lại (`test_threshold_calib.py`, API top_k=3): T=0.76 chặn 30/30 âm, 0/5 dương;
SOFT giữ 0.50 → 27 câu đều được đáp (LOW nếu <0.76). Verify `answer_query` 3/3 legit
được đáp (bút TL027 3.600, HIGH cho câu xe), câu âm "xe đám cưới" vào soft-band
(LOW + không cache, đúng thiết kế). Đổi embedder/corpus phải calib lại ngưỡng.

```bash
cd ai-service
py tests/generation/doc_only/judge_gemma.py --n 3   # thu
py tests/generation/doc_only/judge_gemma.py         # full (resume incremental)
```

```bash
cd ai-service
python tests/generation/doc_only/eval_ragas_full.py --n 30
```

Mỗi row giờ có `elapsed` (giây, từ hỏi đến có đáp án) — cộng trung bình là ra
latency generation DOC, khỏi chạy test latency riêng. DB đã có sẵn
(`llm_200q_report.json`: p50 6.9s, mean 8.1s, max 110s outlier warmup).

Token usage cũng log sẵn mỗi row (`prompt_tokens`, `completion_tokens`, `llm_calls`
từ usage provider thật) — cộng trung bình là ra cost/turn, khỏi đo riêng.
Ngoại lệ: streaming path và judge calls không được tính.
