# LLM Judge Evaluation - RAGAS Metrics for 10 Judged Questions

## Evaluation Criteria

| Metric | Definition |
|--------|------------|
| **Faithfulness** | Answer only contains information derivable from retrieved contexts; no hallucinations |
| **Answer Relevancy** | Answer directly addresses the user's question |
| **Context Precision** | Retrieved contexts are relevant to the question and ranked appropriately |
| **Context Recall** | Retrieved contexts contain all information needed to answer (requires ground truth reference) |

---

## Question-by-Question Evaluation

### Q1: "Quyết định số 917./QĐ-ACT về việc đăng ký và sử dụng xe công tác có hiệu lực từ khi nào?"

**Answer**: "Quyết định số 917./QĐ-ACT có hiệu lực kể từ ngày ký (ngày 08 tháng 9 năm 2025). Căn cứ: Quyết định số 917./QĐ-ACT (Điều 2), Quy định về công tác đăng ký... (Điều 6, Khoản 1)."

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Answer cites specific articles (Điều 2, Điều 6 Khoản 1) from the cited documents. No unsupported claims. |
| Answer Relevancy | **1.0** | Directly answers "when does it take effect" with specific date. |
| Context Precision | **1.0** | Citations point to the exact regulation document in question. |
| Context Recall | **N/A** | No ground truth reference provided. |

---

### Q2: "Quy trình quản lý văn phòng phẩm, vệ sinh phẩm và mực in của công ty có mã hiệu là gì?"

**Answer**: "Mã hiệu của quy trình quản lý văn phòng phẩm, vệ sinh phẩm và mực in là: **QT.ACT.HC-05**. Nguồn: QT.ACT.HC-05 Quy trình... (Trang 1)."

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Direct fact extraction with specific document reference and page number. |
| Answer Relevancy | **1.0** | Precisely answers "what is the code/identifier". |
| Context Precision | **1.0** | Citation matches the exact document name. |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q3: "Hội đồng quản trị Công ty Tài chính Cổ phần Điện lực trình Đại hội đồng Cổ đông xem xét nội dung gì?"

**Answer**: "Mục đích ban hành Quy chế quản trị Công ty Tài chính cổ phần Điện lực là: 1. Bảo vệ quyền và lợi ích hợp pháp của cổ đông và Công ty... 2. Đảm bảo Công ty hoạt động phù hợp với quy định của pháp luật... (Căn cứ: Tài liệu 1 - Phần I, Tài liệu 3 - Điều 2)"

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **0.5** | **ISSUE**: Question asks what content the *Board submits for review* (trình Đại hội đồng xem xét), but answer describes the *purpose of issuing the Governance Regulation* (Mục đích ban hành Quy chế). These are different concepts. The answer may be faithful to retrieved contexts but doesn't match the question's intent. |
| Answer Relevancy | **0.5** | Partially relevant - discusses the Governance Regulation but doesn't answer what specific content was submitted for shareholder review. |
| Context Precision | **0.7** | Contexts appear to be about the Governance Regulation, which is related but not exactly what was asked. |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q4: "Trong tháng 04/2024, lái xe Bùi Xuân Quang nghỉ phép vào ngày nào?"

**Answer**: "Trong tháng 04/2024, lái xe Bùi Xuân Quang nghỉ phép vào ngày **10 (Thứ Tư)**. Trích dẫn: [Tài liệu 1], [Tài liệu 4] (Bảng tổng hợp xe công tác tháng 04.2024)."

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Specific factual claim with document citations pointing to a schedule/table. |
| Answer Relevancy | **1.0** | Directly answers the specific date question. |
| Context Precision | **1.0** | Citations reference the exact document type (vehicle schedule for April 2024). |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q5: "Tôi muốn đăng ký xe đi công tác thì cần gửi yêu cầu cho phòng ban nào?"

**Answer**: "Bạn cần gửi yêu cầu đăng ký xe đi công tác đến **Phòng Hành chính (P.HC)** và phối hợp với nhân viên phụ trách xe của phòng này. Trích dẫn: [Tài liệu 2] Số: 21A/HD-ACT-HC (mục Hướng dẫn và Bước 1); [Tài liệu 3] Điều 5 Khoản 1."

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Specific department name with specific document citations (document number, article). |
| Answer Relevancy | **1.0** | Directly answers "which department". |
| Context Precision | **1.0** | Citations are precise (document ID, section, article). |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q6: "Xe ô tô phục vụ công tác của Công ty Cổ phần Viễn thông ACT được bố trí cho những nhu cầu nào?"

**Answer**: Lists 4 specific use cases: meetings/conferences, business trips to agencies/partners, inspection/survey teams, ad-hoc tasks per leadership direction. Cites: "Điều 2, Khoản 2, Điểm d - Quy định ban hành kèm theo Quyết định số 917/QĐ-ACT"

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Enumerates 4 specific use cases with precise legal citation (Article 2, Clause 2, Point d). |
| Answer Relevancy | **1.0** | Fully answers "for what needs/purposes". |
| Context Precision | **1.0** | Citation points to exact regulation article. |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q7: "Mã hiệu của Quy trình quản lý văn phòng phẩm, vệ sinh phẩm và mực in của Công ty Cổ phần Viễn thông ACT là gì?"

**Answer**: "Mã hiệu... là: **QT.ACT.HC-05**. Trích dẫn: [TÀI LIỆU 1], [TÀI LIỆU 6] - QT.ACT.HC-05 Quy trình quản lý..."

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Same factual answer as Q2, consistent with citations. |
| Answer Relevancy | **1.0** | Direct answer to code/identifier question. |
| Context Precision | **1.0** | Multiple document citations supporting the same fact. |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q8: "Mục đích ban hành Quy chế quản trị Công ty Tài chính cổ phần Điện lực là gì?"

**Answer**: Lists 2 purposes: (1) Protect shareholders' and company's rights, (2) Ensure compliance with laws/charter/standards for max business efficiency. Cites: "Tài liệu 1 - Phần I, Tài liệu 3 - Điều 2"

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Answer matches the question exactly (asks for "mục đích ban hành", answer gives purposes). Citations are specific. |
| Answer Relevancy | **1.0** | Perfect match between question and answer intent. |
| Context Precision | **1.0** | Citations reference the relevant sections. |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q9: "Nếu tôi là cổ đông cá nhân và muốn ủy quyền cho người khác dự họp Đại hội đồng cổ đông thì cần chuẩn bị giấy tờ gì?"

**Answer**: Lists 2 required documents: (1) Power of attorney with shareholder signature and info (notarization not required), (2) ID card/passport of authorized person for verification. Cites: "QuyCheQuanTri-MWG.pdf, Điều 6.3.1 và 6.3.4"

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Specific procedural answer with exact article citations from a named governance document. |
| Answer Relevancy | **1.0** | Directly answers "what documents to prepare". |
| Context Precision | **1.0** | Precise article references (6.3.1, 6.3.4). |
| Context Recall | **N/A** | No ground truth reference. |

---

### Q10: "Quy trình quản lý văn phòng phẩm, vệ sinh phẩm và mực in của công ty có mã hiệu là gì?"

**Answer**: "Mã hiệu... là: **QT.ACT.HC-05**. Nguồn: QT.ACT.HC-05 Quy trình quản lý... (Trang 1)."

| Metric | Score | Reasoning |
|--------|-------|-----------|
| Faithfulness | **1.0** | Duplicate of Q2/Q7, consistent factual answer. |
| Answer Relevancy | **1.0** | Direct answer. |
| Context Precision | **1.0** | Consistent citation. |
| Context Recall | **N/A** | No ground truth reference. |

---

## Summary Scores

| Metric | Average Score | Notes |
|--------|--------------|-------|
| **Faithfulness** | **0.95** | 9/10 questions score 1.0; Q3 scores 0.5 due to question-answer mismatch |
| **Answer Relevancy** | **0.95** | 9/10 score 1.0; Q3 scores 0.5 |
| **Context Precision** | **0.97** | 9/10 score 1.0; Q3 scores 0.7 |
| **Context Recall** | **N/A** | No ground truth references available for any question |

### Overall Assessment

**Strengths:**
- 9 out of 10 answers are highly faithful, relevant, and well-cited
- Strong document grounding with specific article/section references
- Consistent performance on factual/look-up questions

**Weaknesses:**
- **Q3 mismatch**: The question asks what content was *submitted for review*, but the answer describes the *purpose of issuing* the regulation. This appears to be a retrieval or generation issue where the wrong context was used.
- **Context Recall unmeasurable**: Without ground truth references, we cannot verify if retrieved contexts contain ALL necessary information.

**Recommendation**: 
1. Investigate Q3 - check if retrieved contexts actually contain the submission content vs. just the regulation purpose
2. Add ground truth references to enable Context Recall evaluation
3. Consider deduplicating Q2/Q7/Q10 (same question asked 3 times)

---

## Final RAGAS Metrics (Judge-Evaluated)

```json
{
  "faithfulness": 0.95,
  "answer_relevancy": 0.95,
  "context_precision": 0.97,
  "context_recall": "N/A - no ground truth"
}
```