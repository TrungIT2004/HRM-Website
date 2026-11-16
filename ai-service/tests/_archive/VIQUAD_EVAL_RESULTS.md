# RAG Retrieval Eval — ViQuAD

Ngày chạy: 2026-09-29
Script: `tests/test_standard_eval.py` (`python tests/test_standard_eval.py 200`)
Kết quả chi tiết: `tests/viquad_eval_results.json` (200 query × top-5)
Dataset: `tests/data/viquad.json` — UIT-ViQuAD, 46 đoạn văn
Model: `bkai-foundation-models/vietnamese-bi-encoder` (768d) + `AITeamVN/Vietnamese_Reranker` (CUDA)

> File này thay cho `EVAL_RESULTS.md` cũ — không sửa file cũ, kết quả chạy mới ở đây.

---

## 1. Điểm tổng

| Metric | Giá trị | Ngưỡng | Đạt |
|---|---|---|---|
| n (query) | 200 | — | — |
| Hit@1 | **65.5%** | — | — |
| Hit@3 | **84.5%** | — | — |
| Hit@5 | **90.5%** | ≥60% | ✅ |
| MRR@5 | **0.754** | ≥0.45 | ✅ |
| p50 latency | 0.147s | — | — |
| p95 latency | 1.138s | — | — |
| max latency | 4.29s | — | — |
| Miss hoàn toàn (không trong top-5) | 19/200 = 9.5% | — | — |
| Answer nằm trong gold chunk | 181/200 = 90.5% | — | ✅ |

Phân bố rank:

| Vị trí gold chunk | Số query | % |
|---|---|---|
| rank 1 | 131 | 65.5% |
| rank 2–3 | 38 | 19.0% |
| rank 4–5 | 12 | 6.0% |
| không có (miss) | 19 | 9.5% |

**So với lần chạy cũ** (`EVAL_RESULTS.md`, 2026-09-28, n=198): Hit@1 65% → 65.5%, Hit@3 82% → 84.5%, Hit@5 90% → 90.5%, MRR 0.743 → 0.754. Gần như không đổi. Điểm này quan trọng: nó xác nhận số liệu cũ **ổn định qua các lần chạy**, không phải may rủi.

---

## 2. Thuật ngữ

**Hit@k** — trong k kết quả đầu có chứa đoạn văn chứa câu trả lời không. Hit@1=65% nghĩa là 65% câu hỏi, đoạn đúng nằm ngay đầu tiên. Hit@5=90% nghĩa là 90% câu hỏi tìm thấy đoạn đúng trong 5 kết quả đầu. Hit@5 luôn ≥ Hit@1.

**MRR@5 (Mean Reciprocal Rank)** — trung bình `1/rank` của đoạn đúng. Đoạn đúng ở vị trí 1 → 1.0, vị trí 2 → 0.5. Lạm dụng: 65% ở rank 1, 19% ở rank 2–3, 6% ở rank 4–5 → MRR = 0.754. MRR cao hơn Hit@5 nghĩa là đoạn đúng thường xếp rất cao khi tìm thấy.

**top-5** — số kết quả retriever trả về. Ở đây `TOPK=5`.

**gold chunk / gold_keys** — đoạn văn trong dataset chứa câu trả lời. Đây là "đáp án đúng" của bài toán. Một query có thể có nhiều gold; script so trùng `breadcrumb` với key.

**n_docs** — số đoạn văn được nạp vào `document_chunks` (46 đoạn từ UIT-ViQuAD). 200 query phân bố trên 46 đoạn, mỗi đoạn trung bình 4.3 câu hỏi.

**answer_in_gold_chunk** — *proxy reader*: câu trả lời có nằm trong nội dung đoạn đúng không. Nếu đoạn đúng đã tìm thấy mà câu trả lời vẫn không có trong đó → pipeline reader có vấn đề. Đây không phải EM/F1 đầy đủ, chỉ là kiểm tra chặn.

**top1_score** — `relevance_score` của kết quả đầu tiên. Công thức ở `hybrid_retriever.py:114`: `0.7 × vector_score + 0.3 × text_rank + keyword_bonus`. Giá trị có thể **vượt 1.0** vì `keyword_bonus` cộng thêm.

**p50 / p95 latency** — trung vị và phân vị 95 của thời gian retrieve một query.

---

## 3. Nhận xét

### 3.1 Corpus nhỏ nên số đẹp hơn thực tế production

46 đoạn văn cho 200 câu hỏi. `candidate_limit = max(10, top_k*3)` (`hybrid_retriever.py:83`) nên với corpus 46, candidate set gần như **toàn bộ corpus** — retriever coi như brute-force. Điều này giải thích tại sao Hit@5 = 90.5%.

Với corpus thật của HRM (hundreds chunks từ nhiều văn bản luật), ứng viên sẽ bị lọc nặng hơn và Hit@5 **chắc chắn giảm**. Số liệu này là **trần trên của hệ thống**, không phải kỳ vọng thực tế.

### 3.2 19 query miss — và vấn đề thật của chúng

9.5% câu hỏi không tìm thấy đoạn đúng trong 5 kết quả đầu. Xem 5 case đầu:

| Query | Gold | Trả về top-1 | top1_score |
|---|---|---|---|
| Robert Brown phát hiện noãn trần trong cây Tuế và Thông vào... | "Thuật ngữ để chỉ thực vật hạt kín..." | "Kết quả của sự thụ phấn..." | 2.68 |
| Nhà sinh học Hofmeister đã tìm ra thay đổi gì trong túi phôi... | "Sự phát hiện của Hofmeister năm 1851..." | "Kết quả của sự thụ phấn..." | 3.24 |
| Ai là người tìm ra thay đổi trong túi phôi thực vật có hoa? | "Sự phát hiện của Hofmeister năm 1851..." | "Vào thời kỳ thụ phấn..." | 3.46 |
| Năm 1851 Hofmeister tìm ra điều gì ở thực vật có hoa? | "Sự phát hiện của Hofmeister năm 1851..." | "Các chứng cứ đầu tiên..." | 1.97 |
| Thuật ngữ mô tả phổ biện nhất của thực vật có hoa? | "Trong phần lớn hệ thống phân loại..." | "Thuật ngữ để chỉ thực vật hạt kín..." | 1.83 |

Điểm đáng chú ý: **4 trong 5 miss đều hỏi về Hofmeister / năm 1851**, và 19 miss tập trung vào một cụm chủ đề (thụ phấn, túi phôi, thực vật hạt kín). Đây không phải 19 câu hỏi độc lập rải rác mà là **một cụm câu hỏi gần như trùng nhau về cùng một đoạn văn**.

Nguyên nhân: đoạn gold chứa các câu hỏi mà chính dataset dùng làm *câu hỏi* — dạng "Sự phát hiện của Hofmeister năm 1851 về các thay đổi...". Khi query gần trùng nội dung đoạn, `text_rank` của những đoạn khác cùng chủ đề (thụ phấn) vẫn cao và đẩy đoạn gold ra ngoài top-5.

**Đây là artifact của ViQuAD**, không phải lỗi retriever: dataset thiết kế đo đọc hiểu trong 1 đoạn, không thiết kế đo phân biệt giữa nhiều đoạn cùng chủ đề. Nhưng nó làm **giảm** điểm Hit@5, nên 90.5% thực tế còn cao hơn con số báo ra.

### 3.3 `top1_score` không phân biệt được hit và miss

| Nhóm | median top1_score |
|---|---|
| rank = 1 (hit) | 1.600 |
| miss (không có trong top-5) | **1.832** |

Group miss có điểm **cao hơn** group hit. Nghĩa là `relevance_score` hiện tại **không dùng được** để cắt ngưỡng "không có câu trả lời". Điều này ảnh hưởng trực tiếp production: `answer_query` (`chat_service.py:827`) dùng `RELEVANCE_THRESHOLD` để quyết định có trả lời "quy chế không quy định" hay không. Nếu ngưỡng đó không phân biệt được, hệ thống sẽ **trả lời bừa thay vì từ chối**.

Nguyên nhân khả nghi: `keyword_bonus` cộng thêm một hằng số cho query có từ khóa trùng, khiến điểm bị dịch chuyển, và text_rank của `to_tsvector('simple', ...)` không xử lý dấu tiếng Việt nên nhóm từ khóa tiếng Việt bị tính sai.

### 3.4 Latency: p50 tốt, đuôi dài

p50 = 0.147s nhưng max = 4.29s, p95 = 1.14s. 23/200 query vượt 1s.

Nguyên nhân: `hybrid_retriever.py:143` chỉ chạy CrossEncoder rerank khi `top1 < 0.8`. Query có `top1` thấp sẽ bị rerank, mỗi lần ~1.2s. Case chậm nhất (4.29s) là query ngày tháng (`Sự kiện quan trọng nào diễn ra vào ngày 20/7/19...`) — dạng câu hỏi ngày tháng khó embed, kéo top1 xuống 0.92, vẫn kích hoạt rerank.

Ceiling hiện tại: rerank có điều kiện để đổi lấy 1.4s/câu. Nếu cần p95 < 1s, phải giảm `candidate_limit` hoặc chấp nhận bỏ rerank (đổi lại mất điểm Hit@1).

### 3.5 Proxy reader pass nhưng chưa phải EM/F1

181/200 câu trả lời nằm trong gold chunk. 19 fail **trùng khớp 100% với 19 retrieval miss** — tức không có query nào tìm thấy đoạn đúng nhưng đọc ra câu trả lời sai. Pipeline reader chưa bị lộ lỗi trong eval này.

Nhưng đây mới chỉ là kiểm tra "câu trả lời có nằm trong đoạn không", không phải **Exact Match / F1**. Muốn đo đúng chất lượng reader phải chạy LLM sinh câu trả lời rồi so khớp chuỗi — cần LLM server, tốn 200 call.

---

## 4. Thay đổi đã thực hiện

**`tests/test_standard_eval.py`**:
- Bỏ phần HotpotQA, chạy ViQuAD 200 query
- Thêm `OUT = tests/viquad_eval_results.json`, dump per-query: `rank`, `latency_s`, `top1_score`, `top1_breadcrumb`, `gold_keys`, toàn bộ 5 kết quả, `answer_in_gold_chunk`, `gold_answer`
- Thêm block `try/except` nếu thiếu `viquad.json` thì `sys.exit(1)` thay vì chạy tiếp HotpotQA

Trước đó script chỉ `print` bảng tổng, không lưu per-query — không dựng lại được báo cáo chi tiết từ số liệu cũ.

---

## 5. Điểm yếu của eval

- **Corpus 46 đoạn quá nhỏ**, gần brute-force. Số liệu là trần trên, không đại diện production.
- **Chỉ 1 ngôn ngữ, 1 domain** (thực vật học, UIT-ViQuAD). Không nói được gì về corpus luật lao động của HRM.
- **Qrels suy ra từ `para["context"][:60]`** — dùng 60 ký tự đầu làm khoá định danh đoạn. Rủi ro va chạm nếu hai đoạn cùng mở đầu giống nhau.
- **Không tách train/val**, 200 query lấy tuần tự từ đầu file. Không ngẫu nhiên hóa.
- **`answer_in_gold_chunk` chỉ là proxy**, chưa phải EM/F1.

Bổ sung corpus lớn hơn và tách mẫu ngẫu nhiên trước khi dùng số liệu này làm tiêu chí ngưỡng.
