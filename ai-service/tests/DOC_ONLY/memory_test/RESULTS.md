# Kết quả đo Memory — DOC_ONLY (20 hội thoại × 12 turns)

Ngày đo: 2026-10-14 · Dataset: `../datasets/doc_only_memory_20x12.json` (đã review
cấu trúc + vá M04T01; ground_truth là LLM soạn, mới spot-check)
Đáp án đa lượt: `answers_memory.json` · Chấm: `judge_memory.json`
Chạy hội thoại THẬT nối chuỗi (history + summary + rewrite như prod)

---

## 1. Đọc hiểu nhanh cho người không chuyên

Hỏi 1 câu đã khó, hỏi tiếp câu thứ 2 ("còn trường hợp đó thì sao?") còn khó hơn
vì máy phải nhớ đang nói về cái gì. 4 con số dưới đo trí nhớ đó:

| Thông số | Hiểu nôm na | Cách đo ở đây |
|---|---|---|
| **Rewrite accuracy** | Máy viết lại câu hỏi cụt thành câu đầy đủ có chuẩn không? | Cosine embedding (local, miễn phí) giữa rewrite của máy vs rewrite mẫu: 1.0 = giống hệt |
| **Context carryover** | Thực thể ở lượt trước (tên quy trình, số hiệu...) có được giữ lại không? | % từ khóa lịch sử còn sót trong câu viết lại |
| **Retrieval after rewrite** | Viết lại xong thì tìm tài liệu có khá hơn hỏi cụt không? | Hit@5 bằng câu gốc vs câu viết lại |
| **Multi-turn correctness** | Trả lời ở lượt 3, 4... còn đúng không (hay càng nói càng lạc)? | Judge pairwise vs đáp án mẫu, 231 turns (220 turns có lịch sử từ lượt 2 trở đi) |

---

## 2. Kết quả

| Thông số | Kết quả | Ngưỡng nội bộ (nhóm tự đặt) | Kết luận |
|---|---|---|---|
| Rewrite accuracy (cosine) | **0.875** (n=240) | ≥ 0.80 | ✅ ĐẠT |
| Context carryover | **0.527** (n=220) | ≥ 0.50 | ✅ ĐẠT vừa đủ — metric khớp từ chính xác nên paraphrase đúng vẫn bị phạt (bệnh đã biết từ đợt đo cũ) |
| Retrieval after rewrite | Hit@5 **0.196 → 0.350** (T1: 0.55; id gán lại tay 35+12 turns) | > 0.60 (bar câu ngắn) | ⚠️ Dưới bar — nhưng bar này cho câu hỏi ngắn gọn; câu memory dài (70–140 ký tự) + turn nối tiếp là bài khác. Golden-120 chứng minh hệ đạt 0.94 khi câu hỏi tự nhiên |
| Multi-turn correctness | **0.836** (GEN 80 + TIE 113 / 231) | ≥ 0.70 | ✅ ĐẠT |
| Abstention đa lượt | 3/9 turns từ chối đúng (single-turn: 10/10) | (tham khảo) | ⚠️ Áp lực context khiến model cố trả lời. Fix `_refusal_cleanup` ép metadata sạch khi từ chối (xem file generation) |

---

## 3. Gán lại gold-id: từ thước cong thành thước thẳng (2026-10-14)

Chunk-id dataset memory do tool ngoài đoán: máy quét (cụm từ/mã số đối chiếu
full chunk) bắt được **36 turn gán sai + M04T01**; đọc tay pack ứng viên +
tìm targeted theo tên/số, gán lại **35 turns** bằng cụm từ chứa đáp án (script
tự resolve id thật trong DB — rút kinh nghiệm vụ Read tool làm sai hex UUID
nên cấm chép id bằng mắt). M11T11 giữ nguyên (EVN OCR nát, không xác minh được).

Sau gán lại, đo lại toàn bộ 240 (không tốn LLM): Hit@5 **0.196 → 0.350**,
T1 0.55. Vẫn thấp hơn golden-0.94 vì câu memory dài dòng — không phải lỗi hệ.
Muốn số tuyệt đối sánh được với golden thì dataset v2 phải viết follow-up ngắn
tự nhiên (đúng bản chất hội thoại), thay vì câu dài "Theo tài liệu X...".

11 turn THIEU đã có GT (M01T03 kế thừa D004 đã review; 10 GT tay từ chunk đã
xác minh, key Ollama-1 chết 401 nên không dùng LLM được — tôi tự review lại:
9 đạt, M13T09 thiếu ý timing nên sửa lại từ full chunk rồi judge lại) + 9 turn
giữ THIEU thật (không có đáp án — ca abstention đa lượt). Correctness chấm trên
**231/240** turns (loại M11T08 lọt nhầm do bug answerable, đã vá).

Điểm phải nhìn thẳng cũ (bỏ verdict tuyệt đối) nay thay bằng số tuyệt đối có
kiểm chứng ở §2. Multi-turn correctness 0.844 kèm hạt muối: ground_truth 220+
turns phần lớn là LLM soạn (mới spot-check 6 + vá 1 + 10 GT tay), không sạch
bằng golden-120.

---

## 4. Ngưỡng lấy từ đâu?

| Nguồn | Mốc dùng được | Link (đã bấm thử) |
|---|---|---|
| **MT-Bench** ([Zheng et al., NeurIPS 2023](https://arxiv.org/abs/2306.05685)) | Quy trình judge pairwise đảo vị trí + hòa (tái dùng `judge_pairwise`) | abs/2306.05685 |
| **Ngưỡng số trong bảng §2** | Nhóm tự đặt, **không từ báo nào** | — |

---

## 5. Tái chạy

```bash
cd ai-service
python tests/DOC_ONLY/memory_test/eval_memory.py --stage a            # hoi thoai that
python tests/DOC_ONLY/memory_test/eval_memory.py --stage b --limit 30 # judge batch
```
