# Kết quả đo Retrieval — DOC_ONLY (120 câu hỏi)

Ngày đo: 2026-10-14 · Dataset: `../datasets/doc_only_120.json` (120 câu, đã review tay)
Corpus: 10 tài liệu, 663 chunks · Cấu hình chốt đo: `top-K=5`
Pool rerank hiện tại: **×6 (30/biến thể, tối đa ~60)** — xem §2b. Số baseline ×12
lưu ở `retrieval_eval_x12.json`; số đo top_k=10 (cũ) ở `retrieval_eval_topk10.json`.
**Số headline trong file này đo đúng setting prod: top_k=5** (`eval_retrieval.py --top-k 5`).

---

## 1. Đọc hiểu nhanh 

Hãy tưởng tượng thư viện có 663 đoạn tài liệu (chunk). Mỗi câu hỏi đều đã biết
trước **đoạn nào chứa đáp án** (gọi là *chunk vàng*). Hệ thống đi tìm và trả về
5 đoạn khả nghi nhất. 4 con số dưới đây chỉ là 4 cách chấm điểm "tìm có giỏi không":

| Đại lượng | Hiểu nôm na | Ví dụ với 120 câu hỏi |
|---|---|---|
| **Hit Rate@5** | % câu hỏi mà chunk vàng **lọt vào top-5** | 0.90 = 108/120 câu tìm thấy |
| **Recall@5** | % chunk vàng **tìm được** trên tổng số chunk vàng | Ở đây mỗi câu chỉ có 1 chunk vàng nên **bằng hệt Hit Rate@5** |
| **Precision@5** | Trong 5 đoạn trả về, % đoạn **đúng** | Hit@5=0.90 → Precision@5 = 0.90/5 = 0.18 (trần tối đa khi 1 đáp án đúng là 0.20) |
| **MRR@5** | Tìm đúng **càng ở hạng cao càng điểm cao**: hạng 1 được 1 điểm, hạng 2 được 1/2, hạng 3 được 1/3… rồi lấy trung bình | 0.654 ≈ trung bình đáp án đúng nằm ở **hạng ~1.5** |
| **Latency** | Thời gian tìm 1 câu (trung bình / p50 / p95 — p95 nghĩa là 95% câu hỏi xong trong mức này) | p50 ≈ 1.3s, p95 ≈ 1.5s (prod: rerank on, pool ×6, sau fix CTE §2c) |


---

## 2. Kết quả 6 cấu hình (baseline pool ×12)

`vw` = trọng số vector (phần còn lại là lexical/BM25). `rerank` = vòng xếp hạng lại bằng Cross-Encoder.

| Cấu hình | Hit@5 (= Recall@5) | Precision@5 | MRR@5 | Hit@1 | Latency p50 |
|---|---|---|---|---|---|
| vw=0.5, rerank off | 0.825 | 0.165 | 0.586 | 0.450 | 2.7s |
| vw=0.5, rerank **on** | **0.917** | 0.183 | 0.648 | 0.492 | 5.0s |
| vw=0.7, rerank off | 0.783 | 0.157 | 0.593 | 0.492 | 2.7s |
| vw=0.7, rerank **on** | 0.900 | 0.180 | **0.654** | **0.508** | 4.9s |
| vw=0.9, rerank off | 0.742 | 0.148 | 0.558 | 0.458 | 2.7s |
| vw=0.9, rerank **on** | 0.883 | 0.177 | 0.624 | 0.492 | 4.8s |

Chi tiết từng câu hỏi: `retrieval_eval.json` (trường `configs` + `rows`).

Ba phát hiện chính:

1. **Rerank luôn cải thiện ở mọi vw** (+0.09–0.14 Hit@5, +0.06 MRR@5), giá phải trả là +~2.2s latency.
2. **Lexical (BM25) cứu điểm**: vw càng cao (càng bỏ qua từ khóa) thì kết quả càng tệ khi tắt rerank (0.825 → 0.783 → 0.742).
3. **Cấu hình production hiện tại (vw=0.7 + rerank on) đứng nhất MRR@5 = 0.654**, Hit@5 = 0.90, Hit@10 = 0.975 (3/120 câu rớt khỏi top-10: D009, D053, D077 — verify lại 2026-10-15, số cũ 0.983 sai).

### 2b. A/B cắt pool ×12 → ×6 (30/biến thể, tối đa ~60 cho reranker)

Đổi 1 dòng `src/retrievers/hybrid_retriever.py:139`
(`max(40, top_k*12)` → `max(30, top_k*6)`), chạy lại nguyên protocol:

| Cấu hình | Hit@5 ×12 → ×6 | MRR@5 ×12 → ×6 | Latency p50 ×12 → ×6 |
|---|---|---|---|
| vw=0.5 on | 0.917 → **0.908** | 0.648 → 0.643 | 5.0s → 3.9s |
| vw=0.7 on (prod) | 0.900 → **0.875** | 0.654 → 0.639 | 4.9s → 3.8s |
| vw=0.9 on | 0.883 → 0.833 | 0.624 → 0.601 | 4.8s → 3.9s |

Kết luận A/B: **chốt cắt** — mất 3 câu hit@5 (trên sàn 0.85), latency -22%.
Bản ×6 chi tiết trong `retrieval_eval.json`; bản ×12 giữ ở
`retrieval_eval_x12.json`.

### 2c. Đo lại đúng setting prod (top_k=5, pool 30/biến thể)

Các số trên đo với top_k=10 (ao 60/biến thể). Prod chạy top_k=5 (ao 30/biến
thể) nên đo lại — kết quả còn tốt hơn (ao nhỏ, reranker ít nhiễu hơn):

| Cấu hình (top_k=5) | Hit@5 | MRR@5 | Hit@1 | Latency p50 |
|---|---|---|---|---|
| vw=0.5, rerank off | 0.850 | 0.612 | 0.475 | 0.19s |
| vw=0.5, rerank **on** | 0.917 | 0.669 | 0.508 | 0.77s |
| vw=0.7, rerank off | 0.800 | 0.607 | 0.500 | 0.19s |
| vw=0.7, rerank **on** (prod) | **0.942** | **0.686** | **0.525** | 0.76s |
| vw=0.9, rerank off | 0.750 | 0.572 | 0.467 | 0.18s |
| vw=0.9, rerank **on** | 0.925 | 0.650 | 0.492 | 0.75s |

Quan trọng: ở setting prod, **vw=0.7 nhất cả Hit@5 lẫn MRR@5** — câu hỏi
đổi default 0.7→0.5 đóng lại: **giữ 0.7**. (Ở top_k=10 vw=0.5 từng nhất —
bài học: đo đúng setting prod mới kết luận được.)

### 2d. Fix CTE inline — SQL 2.8s → 0.2s/variant (2026-10-14)
**Hệ quả sang Generation: top-5 trùng hệt chỉ 59/120** (overlap trung bình
0.84, đối chiếu `x12_top5.json` vs `top5_ids` bản ×6) → dưới ngưỡng 95% nên
**phải test lại generation cho 61 câu bị đổi context** (đang nợ).

### 2c. Fix CTE inline — SQL 2.8s → 0.2s/variant (2026-10-14)

Profile 5 câu cho thấy SQL nuốt 70–85% thời gian. `EXPLAIN ANALYZE` kết tội:
Postgres ≥12 tự inline CTE `q/total/df/weights` → nhóm `df` tính lại **mỗi
dòng (loops=663, ~3M buffer hits)**, dù index GIN/HNSW đầy đủ. Vá bằng từ khóa
`MATERIALIZED` cho cả 4 CTE (`hybrid_retriever.py`, LEXICAL_WEIGHTS_SQL) —
đúng 4 từ, không đổi toán. Kiểm chứng: top-5 trùng 10/10 mẫu, full eval metrics
y hệt, latency prod **p50 3.8s → 1.3s, p95 5.5s → 1.5s**.

---

## 3. Ngưỡng "đạt chuẩn" lấy từ đâu?

Nói thẳng: **không có ngưỡng chuẩn toàn cầu cho RAG nội bộ**. Các bài báo không
ra "điểm đậu", chúng chỉ công bố điểm của các hệ trên bộ dữ liệu công khai để
làm mốc so sánh. Nhóm mình đặt ngưỡng theo 3 nguồn sau:

### 3.1. Mốc từ bài báo

| Nguồn | Mốc (kèm trang trong bản PDF arXiv) | Ý nghĩa với ta |
|---|---|---|
| **BEIR** ([Thakur et al., NeurIPS 2021](https://arxiv.org/abs/2104.08663) — benchmark 18 bộ dữ liệu retrieval) | BM25 trung bình **nDCG@10 ≈ 0.42**; thêm reranker Cross-Encoder lên **≈ 0.45** (+11%) — **Bảng Table 2, tr.7**; lý do chọn nDCG@10 thay vì Precision/Recall/MRR — **tr.5, §3.2** | Reranker cải thiện ~10% là mức **đúng như lý thuyết** — hệ mình cũng tăng tương đương (+0.06–0.07 MRR@5) |
| **MS MARCO** ([Bajaj et al., 2016](https://arxiv.org/abs/1611.09268) — 8,8 triệu đoạn văn từ Bing; thước đo chính thức là **MRR** theo [script chấm của Microsoft](https://github.com/microsoft/MSMARCO-Passage-Ranking)) | Không trích điểm baseline ở đây vì chưa kiểm chứng được từ nguồn sống — chỉ giữ mốc đã xác minh: task passage ranking + thước đo MRR | Hệ mình MRR@5 = 0.654 đo trên sân nhà 663 chunks — lưu ý §3.3, **không so trực tiếp** với leaderboard mở |
| **RAGAS** ([Es et al., 2023](https://arxiv.org/abs/2309.15217) — bộ đo RAG) | Không công bố ngưỡng đậu/rớt, chỉ so tương đối giữa các phiên bản — đã kiểm tra toàn văn PDF: chữ "threshold" **không xuất hiện lần nào**; định nghĩa metrics ở **§2–3, Bảng Table 1 tr.5** | Nhóm mình cũng dùng ngưỡng để **so phiên bản với nhau**, không coi là chuẩn tuyệt đối |

### 3.2. Ngưỡng nội bộ (kế thừa từ script đo cũ `tests/retrieval_doc_only/`)

| Chỉ số | Ngưỡng cũ | Nguồn gốc |
|---|---|---|
| Hit@5 > 0.60 | Đậu | Do nhóm tự đặt từ đợt đo trước, **không trích từ bài báo nào** |
| MRR@5 > 0.45 | Đậu | Tương tự — mốc nội bộ |
| top1_mean > 0.20 | Đậu | Tương tự |
| fallback_rate < 0.20 | Đậu | Tương tự |

### 3.3. Lưu ý trung thực khi so với bài báo

Corpus của ta chỉ có **663 chunks / 10 tài liệu nội bộ** (BEIR/MS MARCO có tới
hàng triệu văn bản mở). Sân càng nhỏ thì điểm càng cao một cách tự nhiên, nên
**không được kết luận "hệ mình hơn hệ trong báo"**. Giá trị đúng của mốc bài báo
là để kiểm tra *hướng cải thiện* (rerank +~10% ✓, lexical có ích ✓) chứ không
phải để khoe điểm tuyệt đối.

### 3.4. Riêng Hit@1 và Latency p95 — ngưỡng lấy từ đâu?

**Hit@1 = 0.508 — vì sao chỉ "tham khảo"?**
Các bài báo không đặt ngưỡng Hit@1 (BEIR chấm nDCG@10, MS MARCO chấm MRR@10).
Với RAG, LLM đọc cả top-5 chứ không chỉ hạng 1, nên Hit@1 thấp không đồng nghĩa
trả lời sai. Nhưng hạng 1 vẫn đáng quan tâm vì LLM chú ý nhất tới đầu context —
hiện tượng "Lost in the Middle" ([Liu et al., 2023](https://arxiv.org/abs/2307.03172):
tóm tắt ở **tr.1 (abstract)**, kết quả ở **tr.5, §3** — mô hình dùng tốt đầu/cuối
context, kém nhất đoạn giữa). Từ đó nhóm đặt mốc tham khảo **Hit@1 ≥ 0.50**
(ít nhất nửa số câu, bằng chứng tốt nhất nằm ngay đầu) — hệ mình **vừa đủ đậu**.

**Latency p95 = 0.83s — số hiện tại** (đo ở setting prod top_k=5, sau fix CTE;
trước fix: p95 ~5–6.7s tùy batch). Không bài báo nào quy định chatbot phải nhanh
bao nhiêu — đây là quyết định SLO của sản phẩm, căn cứ UX nghiên cứu Nielsen ([0.1s tức thì / 1s giữ mạch /
10s mất tập trung](https://www.nngroup.com/articles/response-times-3-important-limits/)) và thông lệ chatbot (TTFT < 2–3s, tổng < 10s). Hệ mình stream
từng token qua SSE nên TTFT (sẽ đo ở Giai đoạn 5) quan trọng hơn tổng thời gian.
Mốc chính thức cho riêng retrieval: **p95 < 5s** — hiện 0.83s là **ĐẠT** (SLO
chốt 2026-10-14; đổi 1 dòng này là đổi).

---

## 4. Nhận xét: đạt chuẩn chưa?

Đối chiếu cấu hình production hiện tại (**vw=0.7 + rerank on, pool ×6,
top_k=5** — §2c) với ngưỡng nội bộ:

| Chỉ số | Kết quả | Ngưỡng | Kết luận |
|---|---|---|---|
| Hit@5 | **0.942** | > 0.60 | ✅ ĐẠT |
| MRR@5 | **0.686** | > 0.45 | ✅ ĐẠT |
| top1_mean | **0.781** | > 0.20 | ✅ ĐẠT |
| Hit@1 | 0.525 | ≥ 0.50 (tham khảo, §3.4) | ✅ ĐẠT |
| Latency p95 | 0.83s | < 5s (SLO chính thức) | ✅ **ĐẠT** (từ 6.7s → 0.83s: cắt pool + fix CTE + đúng top_k prod) |

**Kết luận chung: Retrieval ĐẠT, giữ vw=0.7 + pool ×6 + CTE MATERIALIZED.**
Việc nợ: (a) test lại generation cho 61 câu đổi top-5 — **XONG 2026-10-15**
(regen full 120 + judge lại, xem file generation); (b) sweep chunk
size/overlap/embedding phải relabel dataset nên để riêng khi có corpus mới.

---

## 5. Tái chạy

```bash
cd ai-service
python tests/DOC_ONLY/retrieval_metrics_tests/eval_retrieval.py        # full 120 cau
python tests/DOC_ONLY/retrieval_metrics_tests/eval_retrieval.py --n 10 # thu nhanh
```
