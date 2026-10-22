# Kết quả đo Performance đơn lẻ — DOC_ONLY (1 câu × 3 lần)

Ngày đo: 2026-10-14 · Script: `perf_single.py` · Kết quả thô: `perf_single.json`
Câu hỏi: "Ai là người lập Giấy cấp phát khăn giấy?" (D050, DOC_ONLY, top-5)
Máy đo: RTX 4050 Laptop 6GB VRAM · LLM qua cloud Ollama (không chạy local được — xem §4)

---

## 1. Đọc hiểu nhanh cho người không chuyên

Người dùng không chờ "tổng thời gian" mà chờ **chữ đầu tiên hiện ra** (TTFT).
Nhờ stream từng token, chữ hiện sau ~3s dù đáp án xong sau ~4s.

| Thông số | Hiểu nôm na | Kết quả (3 lần chạy) |
|---|---|---|
| **TTFT** | Bấm gửi → thấy chữ đầu tiên sau bao lâu? | **1.4 – 2.4s** (sau fix CTE; trước fix: 2.8–3.2s) |
| **Tổng latency** | Bấm gửi → đáp án hiện xong | **2.2 – 3.3s** |
| **Tốc độ sinh** | Máy "nhả chữ" nhanh cỡ nào sau khi bắt đầu | **~180–310 ký tự/s** (≈ 45–78 tokens/s ước lượng*) |
| **RAM** | Bộ nhớ máy dùng | **~2.5 GB**, ổn định cả 3 lần |
| **VRAM** | Bộ nhớ card đồ họa (2 model embedding + reranker) | Process peak **2608 MB**; toàn board **~4.6/6.1 GB** |

\* Stream path không đếm token (xem `USAGE_ACC` trong code) nên tokens/s là ước
lượng chars/4 — chỉ mang tính tham khảo, chars/s mới là số đo thật.

---

## 2. Vì sao latency cao — bóc từng chặng

TTFT ~3s gộp 3 chặng nối tiếp (đo rời từng chặng ở Giai đoạn 2–3):

1. **Rewrite + phân loại** (~1s): 1 LLM call cloud, prompt ~1900 tokens (có cả
   schema DB nhồi sẵn) → chỉ để viết lại câu hỏi.
2. **Retrieval** (~1.5–2s ở top-5): embed (ms) + SQL (~0.2s) + **rerank
   Cross-Encoder trên ~60 ứng viên là miếng to nhất**.
3. **Token đầu của đáp án** (~0.5s): prompt đáp án 3–5k tokens qua cloud.

Khi đã bắt đầu sinh, cloud nhả rất nhanh (240 ký tự trong 0.7s). Nghĩa là
**vấn đề không phải model sinh chậm mà là "thủ tục trước khi sinh" lâu**.

Hai rủi ro đi kèm:

- **Cloud thỉnh thoảng stall**: 1/5 phiên stream ngày đo treo >20 phút không
  log (probe lại thì ngon). Phụ thuộc mạng + hàng đợi ollama.com.
- **VRAM 6GB đã dùng ~75%** chỉ cho embedder + reranker — không có cửa chạy
  LLM 31B local (~20GB). Muốn bỏ cloud thì phải đổi model nhỏ hoặc thêm máy.

---

## 3. SLO chính thức (chốt 2026-10-14, không từ báo nào)

| Thông số | SLO | Hiện trạng | Kết luận |
|---|---|---|---|
| TTFT | < 3s | 1.4–2.4s | ✅ ĐẠT |
| Retrieval p95 | < 5s | 0.83s (file retrieval, sau fix CTE — bản cũ ghi 1.5s) | ✅ ĐẠT |
| Tổng end-to-end p95 | < 5s | 5.21s (rerun generation 10-15, n=120, 3 stall cloud; bản cũ 4.1s trên n=46) | ⚠️ Vượt nhẹ do stall |
| VRAM board | < 90% (để thở khi concurrent) | ~75% | ✅ Còn dư địa nhỏ |

> **Scope:** chỉ đo đơn lẻ (1 query). Test đồng thời/concurrency bị **loại khỏi
> phạm vi** (đồ án, chốt 2026-10-14) — laptop 6GB + cloud free-tier không đại
> diện được cho tải thật; xem xét lại khi có staging đủ mạnh.

---

## 4. Tái chạy

```bash
cd ai-service
python -u tests/DOC_ONLY/performance_test/perf_single.py
```
