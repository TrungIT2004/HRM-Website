# Memory Eval — Conversational Memory trên ViWiki-QR

Ngày chạy: 2026-09-29
Script: `tests/test_memory_sessions.py`
Kết quả chi tiết: `tests/memory_session_results.json`
Dataset: `tests/data/memory_dataset.csv` (1240 turns / 250 sessions)
DB: `hrm_ai`, 10 docx `MEMEVAL_conv_*` (103 chunks)

---

## 1. Bảng điểm tổng

| Metric | Giá trị | Ý nghĩa |
|---|---|---|
| Sessions | 15 | Chọn từ 124 session có ≥5 turns, ưu tiên nhiều turns nhất |
| Turns | 153 | Tổng số lượt hỏi |
| **Graded turns** | **107** | Số lượt thực sự cần rewrite — chỉ nhóm này mới tính điểm rewrite |
| `llm_rewrote` | 107 | Số lượt LLM thực sự đổi nội dung câu hỏi |
| **Rewrite score** | **0.89** | Keyword overlap giữa `rewritten_query` và cột `rewrite` |
| **Answer score** | **0.93** | Keyword overlap giữa `answer` và cột `answer` |
| **Summary** | **15/15** | Cả 15 session đều giữ được entity đầu ở các mốc nén |
| **Recall** | **1.00** | Hỏi lại turn 0 sau khi hết session → vẫn trả lời đúng |

Chi tiết từng session:

| session | turns | graded | llm_rw | rewrite | answer | summary | recall |
|---|---|---|---|---|---|---|---|
| 162 | 14 | 11 | 9 | 0.95 | 0.91 | OK | 1.00 |
| 214 | 13 | 12 | 12 | 0.92 | 0.92 | OK | 1.00 |
| 226 | 13 | 11 | 10 | **0.66** | 0.98 | OK | 1.00 |
| 200 | 12 | 10 | 11 | 0.72 | **0.56** | OK | 1.00 |
| 56 | 10 | 6 | 6 | 0.82 | 0.97 | OK | 1.00 |
| 89 | 10 | 6 | 7 | 1.00 | 0.94 | OK | 1.00 |
| 99 | 10 | 4 | 5 | 0.97 | 1.00 | OK | 1.00 |
| 85 | 9 | 5 | 5 | 0.88 | 0.94 | OK | 1.00 |
| 97 | 9 | 7 | 7 | 0.89 | 0.96 | OK | 1.00 |
| 102 | 9 | 2 | 2 | 1.00 | 0.97 | OK | 1.00 |
| 158 | 9 | 6 | 6 | 0.91 | 0.96 | OK | 1.00 |
| 171 | 9 | 7 | 6 | 0.95 | 1.00 | OK | 1.00 |
| 198 | 9 | 5 | 6 | 0.87 | 0.90 | OK | 1.00 |
| 229 | 9 | 8 | 8 | 0.90 | 1.00 | OK | 1.00 |
| 31 | 8 | 7 | 7 | 0.96 | 0.97 | OK | 1.00 |

---

## 2. Thuật ngữ

**turn** — một lượt hỏi–đáp trong hội thoại. Mỗi turn sinh 2 dòng `chat_messages` (USER + ASSISTANT) qua `save_chat_turn` (`chat_service.py:459`). 10 turns = 20 tin nhắn.

**session / conversation** — toàn bộ chuỗi turn cùng `session_id` trong CSV, tương ứng 1 hàng `chat_conversations`. Mỗi session là 1 cuộc trò chuyện độc lập.

**question** (cột CSV) — câu hỏi **mờ** người dùng thực sự gõ. Thường là pronoun không đứng một mình: *"Ông có quay trở lại lãnh đạo không?"*, *"Còn đông nam?"*.

**rewrite** (cột CSV) — đáp án **chấm trí nhớ**: câu hỏi đã điền đủ đối tượng, đóng vai làm *golden label* để so sánh. Đây KHÔNG phải thứ hệ thống sinh ra — nó là kết quả mong muốn của tính năng memory.

**answer** (cột CSV) — đáp án chấm, là nội dung được nhúng (embed) vào `document_chunks`.

**context_summary** — bản tóm lịch sử dài hạn do LLM sinh, lưu ở `chat_conversations.context_summary`. Đây là thứ giữ nhớ cho các turn đã trôi khỏi buffer 6 tin gần nhất.

**graded turn** — turn có `rewrite != question` trong dataset, tức **thật sự cần** hệ thống viết lại câu hỏi. 107/153 turn rơi vào nhóm này. 46 turn còn lại câu hỏi đã tự nhiên, gọi LLM rewrite là lãng phí và cho điểm 1.0 giả — nên metric tách riêng, hiển thị `null` thay vì điểm.

**llm_rewrote** — boolean cho biết `rewritten_query` có khác `question` hay không. Đo *hành vi thực tế* của LLM, tách biệt với *kết quả mong muốn*. 107 turn LLM đổi câu; con số này trùng `graded` nhưng là sự trùng ngẫu nhiên, hai metric khác nhau về bản chất.

**rewrite score** — `|content_words(expected) ∩ content_words(actual)| / |content_words(expected)|`, dùng `\w{4,}` và loại stopword tiếng Việt. Câu càng ngắn gọn càng dễ đạt 1.0.

**answer score** — cùng công thức, áp cho `answer`. Nhưng hệ thống trả lời dài hơn nhiều lần nên điểm cao hơn rewrite score.

**summary check** — ở mỗi mốc 8/14/20 tin nhắn, `GET /chat/conversations/{id}` rồi đo keyword overlap giữa `context_summary` và `rewrite` của **turn 0**. Đạt nếu ≥0.5. Mốc này do `answer_query` (`chat_service.py:920`) kích hoạt `summarize_context_background` chạy background.

**recall** — hết session, hỏi lại câu turn 0. Lúc này lịch sử đã bị nén 2–3 lần, chỉ còn `context_summary` + 4 tin gần nhất. Đạt = memory dài hạn còn nguyên entity đầu.

---

## 3. Nhận xét

### 3.1 Memory dài hạn hoạt động tốt — đây là điểm mạnh thật

`summary_ok = 15/15`, `recall = 1.00`. Cơ chế 3 tầng của `chat_service.py` được verify đúng như thiết kế:

- `ensure_context_summary` (`:300`) dựng summary từ lịch sử khi chưa có
- `summarize_context_background` (`:195`) nén dồn ở mốc 8/14/20
- `condense_question` (`:333`) nối `summary` + 4 tin gần nhất thành câu hỏi độc lập

37 mốc nén được ghi nhận, 7 session đủ 10 turns để chạm cả 3 mốc. Không session nào mất entity đầu ở bất kỳ mốc nào. Với 9–14 turns — tức 18–28 tin nhắn, vượt buffer 6 tin — đây là bằng chứng nén summary không bị rò rỉ thông tin.

### 3.2 Rewrite 0.89 nhưng điểm này có giới hạn đo lường

0.89 là trung bình trên 107 turn. Phân tích turn thấp cho thấy phần lớn **không phải lỗi của LLM rewrite**, mà là khác biệt cách diễn đạt:

```
t8  session 226
  Q   : Nhà nước này có được lòng dân không?
  WANT: Nhà nước Thục Hán có được lòng dân không?
  GOT : Thục Hán có được lòng dân không?          → 0.67
```

Hệ thống **bám đúng entity** (Thục Hán), chỉ gọi tắt. Metric trừ điểm vì thiếu chữ "nhà nước". Tương tự:

```
t11 session 226
  WANT: Gia Cát Lượng có tước hiệu gì?
  GOT : Trong thời Tam Quốc, vị quân sư của nhà Thục Hán có tước hiệu gì?   → 0.67
```

Nhưng ở đây hệ thống lại **không bám entity** — nó dùng mô tả vị trí thay vì tên `Gia Cát Lượng`, dù câu trả lời đúng là có tên trong context. Ở t12 nó lại bám đúng (`Zhuge Liang`). Tức `condense_question` bám entity **không ổn định** khi entity nằm sâu hơn 4 tin gần nhất và chỉ còn trong `context_summary`.

Một số turn thất bại thật:

```
t5  session 200
  Q   : Cái đầu tiên là gì?
  WANT: Honduras là gì?                          → 0.00
  GOT : Cái đầu tiên trong thông tin về Guatemala là gì?
```

Đây là lỗi thật: LLM **hiểu sai** mãi điểm. "Cái đầu tiên" trong dataset là danh sách nước giáp biên mà lượt trước đang liệt kê (Honduras), nhưng LLM hiểu là "mục đầu tiên trong thông tin". Câu hỏi pronoun 2 từ không đủ ngữ cảnh để LLM đoán, dù có summary.

### 3.3 Answer 0.93 bị kéo xuống bởi một failure mode duy nhất

5 turn có `answer_score = 0` trong toàn bộ 153 turn, tất cả thuộc session 200. Không phải lỗi hiểu sai — là **rớt ngưỡng liên quan**:

| turn | question | expected answer | citations | kết quả |
|---|---|---|---|---|
| t2 | Tây nam thì sao? | `Thái Bình Dương` | 3 | "không có thông tin" |
| t3 | Đông bắc? | `Belize và Biển Caribe` | 3 | "không có thông tin" |
| t4 | Còn đông nam? | `Honduras cùng El Salvador` | 0 | "không có thông tin" |
| t5 | Cái đầu tiên là gì? | `Honduras là một quốc gia tại Trung Mỹ...` | 0 | "không có thông tin" |
| t8 | Việc đó dẫn đến hậu quả gì? | `Từ 1960, ... 200.000 thường dân...` | — | "không có thông tin" |

Đáng chú ý: **expected answer ở t2 chỉ 2 từ** (`Thái Bình Dương`), dưới `min_chunk_chars = 80` của `legal_chunker.py:13`. Chunk đó không tồn tại trong `document_chunks`, nên hệ thống không có gì để trả lời. Đây là hậu quả trực tiếp của việc 47% answer trong dataset ngắn hơn ngưỡng chunker.

Đây là giới hạn của **cách dựng test data**, không phải của hệ thống memory. Script đã workaround bằng cách gộp `question + rewrite + answer` vào body docx để mọi chunk đủ 80 ký tự, nhưng với answer 2 từ thì body vẫn chỉ ~70 ký tự và bị rớt.

Fix đúng hơn: hạ `min_chunk_chars` trong `legal_chunker.py`, hoặc cho phép chunk câu trả lời ngắn. Đây là quyết định production, chưa thực hiện.

### 3.4 Chi phí LLM

Một lần chạy đầy đủ (10 session, ingest từ đầu) tiêu ~258 LLM call:

| Nguồn | Calls | Tỉ lệ |
|---|---|---|
| `MetadataEnricher` (2 calls/chunk × 103 chunks) | 206 | 80% |
| `summarize_context_background` (37 mốc) | 37 | 14% |
| `ensure_context_summary` (turn 1 × 15) | 15 | 6% |
| smart title (15 session) | 15 | 6% |
| `condense_question` (107 turn) | 107 | — |

Sau khi sửa `_retrieve_lazy` (`chat_service.py:709`) để luôn gọi condense, `condense_question` tăng từ ~5 lên 107 call. Đổi lại metric rewrite trở nên có ý nghĩa. Đây là cái giá đo được — trước đó chỉ 5 call nhưng điểm 0.75 là ảo.

80% chi phí nằm ở enrichment lúc ingest, không liên quan gì đến việc đo memory. Tái dùng docx đã ingest giảm từ 258 xuống 52 call.

---

## 4. Thay đổi đã thực hiện

**`src/chat/chat_service.py:709`** — `_retrieve_lazy` trước đây chỉ gọi LLM rewrite khi retrieval trượt ngưỡng:

```python
if (chunks and top1 >= RELEVANCE_THRESHOLD) or not recent_history:
    return chunks, question, context_summary     # trả nguyên câu hỏi
```

104/109 turn rơi vào nhánh này, tức tính năng rewrite gần như không chạy. Đã sửa thành: có history thì luôn condense trước, rồi retrieve 1 lần bằng câu đã rewrite. Turn 0 (chưa có history) giữ nguyên câu gốc. Việc này cũng cắt được 1 vòng retrieve thừa.

**`tests/test_memory_sessions.py`** — metric chấm riêng nhóm `needs_rewrite`, thêm cột `llm_rewrote`, thêm stopword tiếng Việt, dọn `semantic_cache` trước mỗi lần chạy.

---

## 5. Điểm yếu của metric

- **Keyword overlap không phân biệt paraphrase với sai.** Câu đúng ý nhưng gọi tắt bị trừ; câu sai entity có thể trùng từ nên vẫn qua. Session 226 minh hoạ cả hai chiều.
- **Stopword tiếng Việt hard-code, không dùng NLP.** Từ khóa có nghĩa như `diện tích` có thể bị bỏ nếu rơi vào danh sách, làm nhiễm điểm.
- **Answer score thiên lệch theo độ dài.** Hệ thống trả lời dài hơn nhiều lần gold answer, nên 0.93 không có cùng nghĩa với rewrite 0.89.
- **Chỉ 15 session, chọn theo số turns.** Chưa đại diện cho conversation dài hơn 14 turns, cũng không ngẫu nhiên hóa.

Nâng lên embedding similarity hoặc LLM-as-judge khi cần phân biệt paraphrase với sai.
