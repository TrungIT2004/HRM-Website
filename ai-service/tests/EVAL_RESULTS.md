# Kết quả Eval RAG (Retrieval) — ai-service

Ngày chạy: 2026-09-28. Script: `tests/test_standard_eval.py` (chuẩn BEIR mini-corpus).
DB: `hrm_ai` — 1 doc `bo-luat-lao-dong-2019.docx` (COMPLETED, 246 chunks), `semantic_cache` = 0.
Model: embed `bkai-foundation-models/vietnamese-bi-encoder` (768d) + rerank `AITeamVN/Vietnamese_Reranker`, chạy CUDA.
Fix đã áp dụng từ số liệu: chỉ rerank khi `top1 < 0.8` (`hybrid_retriever.py`); `max_length` 1024→512 (`cross_encoder_reranker.py`).

## 1. Bảng điểm chính thức

| Đề (ngôn ngữ) | n (câu hỏi) | Hit@1 | Hit@3 | Hit@5 | MRR@5 | p50 | max | Đạt? |
|---|---|---|---|---|---|---|---|---|
| HotpotQA (Anh) | 100 | 40% | 64% | 78% | 0.532 | 0.74s | 512.7s | ĐẠT |
| ViQuAD (Việt) | 198 | 65% | 82% | 90% | 0.743 | 0.22s | 670.2s | ĐẠT |

Ngưỡng đạt (mini-corpus): `Hit@5 ≥ 60%`, `MRR ≥ 0.45`. Tiếng Việt mạnh hơn tiếng Anh vì embedder/reranker là model Việt.

## 2. Số đo chẩn đoán (1 câu mẫu)

| Chặng | Thời gian | Ghi chú |
|---|---|---|
| Embed query | 0.38s | OK |
| SQL hybrid search (0.7 vector + 0.3 keyword) | 0.25s | OK |
| Rerank 5 ứng viên | 6.94s (~1.4s/cặp) | Thủ phạm chậm → đã gate + giảm max_length |

Smoke test n=5: rerank ON cho Hit@1=100%/MRR=1.0 nhưng 25s/câu; tắt rerank còn Hit@1=40%/MRR=0.62 nhưng 0.2s/câu. ViQuAD smoke n=9 (no-rerank): Hit@1=78%/MRR=0.86, 0.2s/câu.

## 3. Giải thích ký hiệu và đại lượng

- **Hit@k** — % câu hỏi mà tài liệu đáp án lọt vào top k kết quả. VD `Hit@5=90%` = 90/100 câu tìm thấy đáp án trong 5 kết quả đầu. k càng nhỏ càng khó.
- **MRR@5 (Mean Reciprocal Rank)** — trung bình của `1/hạng đáp án đúng` (chỉ tính trong top 5). Đáp án hạng 1 được 1 điểm, hạng 3 được 0.33, ngoài top 5 được 0. VD `MRR=0.74` ≈ đáp án trung bình nằm ở hạng ~1.3. Vừa đo "tìm thấy" vừa đo "xếp hạng cao".
- **p50** — trung vị latency: 50% câu chạy nhanh hơn số này. Đây là tốc độ thật của hệ thống.
- **max** — câu chậm nhất. Ở đây là nhiễu warmup CUDA + autovacuum Postgres sau bulk-insert (q1: 376s), bỏ qua khi đánh giá.
- **top1** — điểm `relevance_score` của kết quả đầu (thang ~0–1.5: 0.7 vector + 0.3 keyword + bonus). Ngưỡng gate 0.8: top1 ≥ 0.8 nghĩa là coarse đã tự tin → bỏ qua rerank.
- **n** — số câu hỏi được chấm (không phải số tài liệu). Kho mini HotpotQA có 991 docs/100 câu; ViQuAD có 123 docs/198 câu (nhiều câu chung 1 đoạn).

## 4. Nguồn dataset

- HotpotQA distractor, HF `hotpotqa/hotpot_qa`, split validation (public, không cần xin phép). Mỗi câu: multi-hop 2 bước, 2 tài liệu vàng + 8 đoạn nhiễu.
- ViQuAD, file `tests/data/viquad.json` (138 articles / 28.457 QA, split train, mirror Kaggle `nguyendolikeyou/uit-viquad`; bản gốc cần ký agreement với UIT). Dùng làm kho retrieval là hợp lệ (không train model lên nó).

## 5. Giới hạn của test này (chưa đo)

1. Generation: LLM viết đáp án có bịa không (cần dựng server + gọi LLM) → bài tiếp theo `test_faithfulness.py`.
2. PBAC phân quyền: test dùng quyền `ALL`, chưa đo rò rỉ tài liệu giữa phòng ban.
3. Hội thoại nhiều lượt: HotpotQA/ViQuAD toàn câu độc lập, chưa đo khả năng nhớ ngữ cảnh (cần QReCC/UIT-ViCoQA hoặc 20 câu viết tay trên BLLĐ).
