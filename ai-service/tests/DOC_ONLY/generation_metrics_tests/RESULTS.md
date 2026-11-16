# Kết quả đo Generation — DOC_ONLY (120 câu golden + 10 câu negatives)

Ngày đo: 2026-10-14 (bản gốc) · **chạy lại full 2026-10-15** sau fix CTE + ngưỡng
0.76 (đáp án RAG: `answers.json` · backup bản cũ: `answers.bak-20261015.json`;
judge: `judge.json` · backup: `judge.bak-20261015.json`; audit cũ:
`audit_hallucination.bak-20261014.csv`). Đáp án RAG: `answers.json` · Chấm judge: `judge.json`
Latency từng câu: `latency_per_question.csv` (130 dòng, sinh lại cùng rerun 10-15 —
bản cũ 74+46 dòng giữ trong git history, không còn giá trị).
Context freeze: top-5, vw=0.7 + rerank (cấu hình production đã chốt ở Giai đoạn 2)

---

## 1. Đọc hiểu nhanh cho người không chuyên

Máy đã tìm được tài liệu (Giai đoạn 2). Giờ hỏi: **viết câu trả lời có giỏi không?**
Chuẩn chấm là 120 đáp án mẫu đã review tay. Vì thuê người chấm 120 câu đắt,
nhờ một LLM khác (key mới, tài khoản khác) làm giám khảo, theo đúng quy trình
chống thiên vị: chấm 2 lượt đảo vị trí, cho phép xử hòa, bắt giải thích bằng
chứng trước khi kết luận.

| Thông số | Hiểu nôm na | Cách đo ở đây |
|---|---|---|
| **Answer correctness** | Câu trả lời có đúng như đáp án mẫu không? | Judge so cặp Ground truth vs Generated, 2 lượt đảo A/B: thắng + hòa = đạt |
| **Faithfulness** | Từng ý trong câu trả lời có được tài liệu hậu thuẫn không? | Judge gắn cờ bịa + bộ verifier đếm câu không khớp context |
| **Answer relevance** | Có trả lời đúng trọng tâm câu hỏi không? | Judge chấm 1–5 trong cùng lượt chấm |
| **Hallucination rate** | % câu trả lời chứa thông tin sai/không nguồn | % câu bị judge gắn cờ ≥ 1 lượt |
| **Citation accuracy** | Nguồn trích dẫn có thật sự chứng minh nội dung không? | 2 lớp: máy kiểm (nguồn có trong top-5 đã thấy?) + judge duyệt (nguồn có chứng minh?) |
| **Abstention accuracy** | Không có đáp án trong tài liệu thì có biết từ chối không? | 10 câu bẫy ngoài corpus (WFH, ESOP, gym...), kiểm cụm từ từ chối |

---

## 2. Cách chấm (để ai cũng tái hiện được)

1. **Sinh đáp án** (`run_answers.py`, key RAG cũ): `answer_query(top_k=5)`,
   purge semantic cache trước khi chạy để đáp án tươi; ghi `elapsed_s`,
   tokens, citations, confidence, dropped_claims từng câu.
2. **Judge pairwise** (`judge_pairwise.py`, key mới): mỗi câu 2 calls —
   lượt 1 (A=mẫu, B=máy), lượt 2 đảo lại. Judge thấy **FULL top-5 chunk**
   (`--full-context`) — bản đầu cắt mỗi chunk còn 600 ký tự khiến judge xử oan
   chi tiết nằm ở nửa sau chunk (xem §4). Hợp nhất: đồng thuận → final;
   thắng+hòa → thắng (yếu); ngược nhau → **DISPUTED** (cần người xem lại).
   Rerun 10-15 chấm full-context cho cả 120 câu (không giữ verdict cũ).
3. Độ dài đáp án chỉ cảnh báo (lệch >3x), không quyết thắng thua.

---

## 3. Kết quả (sau test bù 46 câu đổi context do cắt pool ×12→×6)

> Rerun full 120 câu 2026-10-15 (sau fix CTE + ngưỡng 0.76, judge `--full-context`):
> **GT thắng 11 · Máy thắng 31 · Hòa 73 · Disputed 5** (bản 10-14: 12 / 38 / 64 / 6).

| Thông số | Kết quả | Ngưỡng nội bộ (nhóm tự đặt) | Kết luận |
|---|---|---|---|
| Answer correctness | 0.850 → **0.867** ((31+73)/120; bản cũ tính trên câu phân định được: 0.895) | ≥ 0.70 | ✅ ĐẠT |
| Answer relevance | 4.88 → **4.87**/5 | ≥ 4.0 | ✅ ĐẠT |
| Citation (máy kiểm) | 0.913 → **0.895** nguồn nằm trong top-5 đã thấy | ≥ 0.85 | ✅ ĐẠT |
| Citation (judge duyệt) | 0.767 → **0.758** nguồn thật sự chứng minh | (tham khảo) | ⚠️ Vẫn thấp hơn máy kiểm — xem §4 |
| Faithfulness / Hallucination | judge 0.150 → **0.133** (16 câu cờ, audit tay đang làm) ; bản cũ audit tay 0.033 (4/120) | < 0.20 | ✅ ĐẠT tạm (chờ audit mới) |
| Abstention | 10/10 → **10/10** (N007 đáp đúng một phần mục 3.9 rồi từ chối phần laptop — vẫn chứa cụm từ chối chuẩn) | ≥ 8/10 | ✅ ĐẠT |
| Latency end-to-end (n=120) | mean 4.86 → **3.43s** (−1.42s nhờ fix CTE), p50 4.77 → **3.16s**; **p95 5.21s** (3 stall cloud 11–12s) | < 5s (SLO chính thức) | ⚠️ **p95 vượt SLO do stall** — xem dưới |

Rerun 10-15 ghi nhận thêm:
* **Latency thật ra GIẢM**: đối chiếu từng câu cũ→mới (backup `answers.bak-20261015.json`),
  mean −1.42s, p50 4.77→3.16s — đúng hiệu quả fix CTE (SQL 2.8s→0.2s/variant).
  p95 5.21s cao chỉ vì **3 stall cloud** 11–12s (D022/D077/D094, bệnh đã biết) +
  2 đáp án dài ~7s. Không phải SQL chậm lại. p90 = 4.15s vẫn trong SLO.
* 42/120 đáp án gắn cờ LOW (band [0.50, 0.76) sau nâng ngưỡng) — nội dung vẫn chấm
  ngang GT (correctness 0.850 → 0.867), cờ LOW chỉ ảnh hưởng metadata, không kéo điểm.

---

## 4. Vì sao hallucination từng vọt lên 0.467 — và con số thật là gì

Bản judge đầu cắt mỗi chunk còn 600 ký tự để tiết kiệm token. Hệ quả: đáp án
RAG (được dặn "liệt kê cả chi tiết ở nửa sau chunk") chứa thông tin đúng nhưng
nằm ngoài đoạn judge được thấy → judge xử oan. Kiểm chứng độc lập: lấy quote
bị cờ đi dò trong FULL top-5, **15/50 câu đối chiếu được là oan 100%**, 21 câu
cờ bất đồng giữa 2 lượt (judge tự mâu thuẫn).

Chấm lại 56 câu bị cờ với full context: hallucination **0.467 → 0.167**,
correctness **0.758 → 0.892**, disputed **17 → 3**, citations_ok **0.617 →
0.800**. Test bù 46 câu đổi top-5 (cắt pool): correctness **0.850**,
hallucination **0.150**. Rồi **audit tay toàn bộ 18 câu còn cờ**
(`audit_hallucination.csv`, người chấm độc lập họ model với judge) — số liệu
bản 10-14; verdicts cũ giữ ở `audit_hallucination.bak-20261014.csv` (file live
đã sinh lại cho rerun 10-15: 16 câu cờ mới, verdict trống, cộng D067/D116
disputed-nhưng-không-cờ cần ngó tay thêm).

1. **Hallucination thật: 4/120 ≈ 0.033.** 14/18 cờ là oan (quote nguyên văn
   trong context; judge nhầm omission/header thành bịa; GT ghi số của công ty
   khác trong khi câu hỏi mở). 4 ca thật toàn cùng 1 bệnh: **từ chối sai**
   (D009/D044/D077: thông tin có trong chunk mà bảo không có) + **trích nguồn
   ma sau câu từ chối** (D009) + thêm nghĩa trong ngoặc (D010). Verdict từng câu
   trong cột `verdict` file CSV.
2. **Trích dẫn thiếu vệ sinh ở câu từ chối — ĐÃ FIX.** N007/N008/N010 từ chối đúng
   ("không có thông tin...") rồi lại gắn thêm dòng "Căn cứ: ..." + nhãn HIGH —
   đã thêm `_refusal_cleanup` trong `chat_service.py` (từ chối → citations rỗng +
   confidence LOW, không cắt text). Verify 19 câu: 10/10 refusals sạch metadata.

---

## 5. Ngưỡng lấy từ đâu?

| Nguồn | Mốc dùng được | Link (đã bấm thử) |
|---|---|---|
| **MT-Bench** ([Zheng et al., NeurIPS 2023](https://arxiv.org/abs/2306.05685)) | Quy trình judge chuẩn: đảo vị trí chống position bias, cho hòa, giải thích được — judge mạnh khớp người >80%. *Không ra điểm đậu.* Nhóm mình copy quy trình, và nói rõ judge cùng họ model nên yếu hơn GPT-4 của báo | abs/2306.05685 |
| **RAGAS** ([Es et al., 2023](https://arxiv.org/abs/2309.15217)) | Định nghĩa faithfulness / answer relevancy — *không ngưỡng đậu/rớt* (đã kiểm tra toàn văn, chữ "threshold" không xuất hiện) | abs/2309.15217, Bảng Table 1 tr.5 |
| **Ngưỡng số trong bảng §3** | Do nhóm tự đặt theo ý nghĩa sản phẩm (vd correctness ≥ 0.70 = 7/10 câu dùng được), **không trích từ báo nào** — giống cách đặt ngưỡng retrieval | — |

---

## 6. Tái chạy

```bash
cd ai-service
python tests/DOC_ONLY/generation_metrics_tests/run_answers.py            # sinh dap an (resume)
python tests/DOC_ONLY/generation_metrics_tests/judge_pairwise.py --limit 30  # cham theo batch
python tests/DOC_ONLY/generation_metrics_tests/latency_stats.py --csv   # thong ke latency
```
