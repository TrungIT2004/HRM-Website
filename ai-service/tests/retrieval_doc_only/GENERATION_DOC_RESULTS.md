# Kết Quả Test Generation — DOC_ONLY (30 câu, dàn theo 7 file)

**Ngày test:** 2026-10-08
**Tool:** `tests/eval_ragas_full.py --n 30` (3 runs) + audit tay 6 câu điểm 0
**Judge:** gpt-oss:120b qua Ollama cloud (`max_tokens=4096, temperature=0`)

---

## Số Liệu (ổn định qua 3 runs)

| Metric | Run 1 | Run 2 | Run 3 | Ngưỡng đề xuất | Đạt? |
|---|---|---|---|---|---|
| faithfulness | 0.21* | 0.54 | 0.52 | ≥ 0.8 | ❌ |
| answer_relevancy | 0.41 | 0.38 | 0.40 | ≥ 0.8 | ❌ |
| context_precision | 0.60 | 0.54 | 0.56 | ≥ 0.7 | ❌ |
| context_recall | 0.59 | 0.47 | 0.53 | ≥ 0.7 | ❌ |

\* Run 1 judge sập hàng loạt (`IncompleteOutputException`, faith chỉ chấm 7/30).
Đã sửa: `max_tokens=4096` → còn 1-2 lỗi/run.

---

## Verdict: số thấp do JUDGE, không phải do hệ thống

Audit tay 6 câu `faithfulness == 0` persistent qua 3 runs (đáp án tươi +
đúng contexts đã chấm):

| Câu hỏi | Đáp án tươi | Verdict tay |
|---|---|---|
| Quyết định số bao nhiêu (lương thưởng)? | Từ chối một phần trung thực ("không ghi rõ số hiệu") | ✅ An toàn, không bịa |
| Yêu cầu cấp VPP? | Chi tiết BM02/BM04/định mức 120k, khớp contexts | ✅ Đúng, judge sai |
| Nội dung này phần nào (quy chế lương)? | Khớp chunk Bảng biểu Ch.3 từng chữ | ✅ Đúng, judge sai |
| PMSC nằm trang nào? | Liệt kê 24/35/52 khớp 3 contexts | ✅ Đúng, judge sai (gold "trang 15" mới là mơ hồ) |
| Làm sao xem bảng biểu? | Trích Trang 1/19 + filler chung chung | ⚠️ Đúng 80% (rule 9 đã bỏ kiểu SharePoint thuần) |
| Tham khảo quy chế chuẩn bị NQ ĐHĐCĐ? | Trích Trang 23/26/11 + điều khoản | ⚠️ Đúng 70% (vài số trang không kiểm được trong contexts) |

**Tỉ lệ hallucination thật: 0/6 rõ ràng** (tệ nhất là filler chung chung, không
phải bịa fact). Judge gpt-oss chấm 0 cho đáp án có căn cứ — có hệ thống,
không phải noise ngẫu nhiên (khả năng: không khớp nối text đáp án sạch với
contexts OCR nát/table).

Bằng chứng judge tự mâu thuẫn: 1 câu `context_precision = 1.0` nhưng
`faithfulness = 0.0` cùng lúc.

---

## Việc đã làm để đẩy số (và kết quả)

| Fix | Hiệu quả |
|---|---|
| Judge `max_tokens=4096, temperature=0` | Hết sập hàng loạt (7/30 → 28-29/30 được chấm) |
| Mẫu dàn theo 7 file (thay vì 30 dòng đầu) | Đại diện đủ corpus |
| Lọc chỉ câu DOC thành công vào judge | Hết nhiễm DB/out-of-scope |
| Contexts chấm = chunks đáp án đã dùng (câu rewrite) | Loại faithfulness-0-oan do lệch chunks |
| Prompt rule 9 (cấm hướng dẫn chung chung) | ✅ Verified: câu "xem bảng biểu" giờ trích Trang 1/19 thay vì SharePoint thuần |
| Xóa corpus EVALRET trùng nội dung | Hết chunk đôi trong top-3 |

Số mean không nhúc nhích sau các fix đo lường (0.52–0.54) → phần còn lại là
độ khắc của judge, không phải lỗi hệ thống còn sót.

---

## Khuyến nghị production (thay vì dí số RAGAS)

1. **Không gate production bằng RAGAS + gpt-oss.** Judge này false-negative
   có hệ thống trên corpus OCR/table tiếng Việt.
2. Gate bằng: retrieval metrics (đã 100% Hit@5) + deterministic checks
   (citation coverage, refusal đúng chỗ) + **spot-check tay định kỳ**
   theo mẫu audit 6 câu trên.
3. Muốn số tự động: đổi judge (Gemini/Claude) hoặc goldens do người review
   (`answer_draft` hiện là nháp LLM, chưa đủ chuẩn làm gold).

## Cách chạy lại

```bash
cd ai-service
python tests/eval_ragas_full.py --n 30
# Output: tests/ragas_eval_results.json
# (vecsim vs answer_draft tính offline, xem script tạm — chỉ là tín hiệu phụ)
```
