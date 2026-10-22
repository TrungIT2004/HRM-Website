# Kết quả test Memory rewrite — dữ liệu NỘI BỘ (30 conv × 12 turns)

**Ngày chạy:** 2026-10-12 | **Tool:** `test_memory_sessions.py` (đường prod `rewrite_and_route_step`)
**Dataset:** `memory_internal.csv` (sids 1001–1030: xe, lương, VPP, EVN/MWG/Petrolimex, quản trị)
→ `memory_internal_results.json` (từng câu + route)

## Số chính

| Metric | Giá trị |
|---|---|
| rewrite_score | **0.333** (120b) → **0.348** (fix router) → **0.390** (gemma) → 0.397 (few-shots, ~nhiễu) |
| llm_rewrote | 326 → 335 → 323 → 320/360 turn |
| route | DOC_ONLY 317→324→346→**344** / DB_ONLY 25→16→11→11 / DIRECTORY 8→8→1→**3** |

## ⚠️ Không so được với 0.863 — khác bài thi, không phải prod tệ đi

Số cũ đo trên QRECC (kiến thức chung, ~30% turns độc lập được miễn chấm, rewrite kỳ vọng ngắn).
Số này đo trên blueprint tự viết: 359/360 turns bắt viết lại + rewrite kỳ vọng dài, cụ thể
(kèm tên tài liệu). Code prod giữa 2 lần chạy **không đổi gì ở đường rewrite**.
0.333 là điểm trên thước chặt hơn, không phải regression.

## Mổ fail (mẫu 14 câu 0.0)

| Cụm | Ví dụ | Bản chất |
|---|---|---|
| LLM giữ nguyên câu không đại từ | `P.HC là đơn vị nào?` → giữ nguyên (thiếu `...theo hướng dẫn 214.HD-ACT-HC`) | Gold đúng (câu đơn lẻ mơ hồ), LLM lười. Nhẹ. |
| Đọc sai động từ trần | `Ký từ bao giờ?` → `Tôi cần ký từ ngày nào?` (ký = hiệu lực, không phải ký tên) | Lỗi thật, câu cụt tiếng Việt. |
| Neo nhầm thread cũ | `Trả khi nào?` → lôi `điện thoại cho bảo vệ` từ turn xa; `Vi phạm thì bị gì?` → lôi chuyện đi đêm | Lịch sử nhiều chủ đề + câu ngắn → LLM bắt neo sai. Blueprint nhảy chủ đề nhanh cũng góp phần. |
| Route sai trên câu HR ngắn | `Đi gấp trong đêm thì báo ai?` → DIRECTORY; `Vi phạm thì bị gì?` → DB_ONLY | Lỗi routing thật: câu tài liệu bị đẩy sang pipeline DB/danh bạ. Đáng fix riêng. |

## Kết luận dùng được

* Rewrite câu có đại từ rõ (`nó/đó/cái đó`) trên tài liệu nội bộ: ổn (các turn dài điểm cao, xem JSON).
* Yếu đúng 2 chỗ: câu cụt <5 từ không đại từ, và neo sai khi conv nhảy chủ đề.
* Route câu ngắn có vấn đề riêng (DIRECTORY/DB_ONLY oan) — đã thêm guard vào router
  (`REWRITE_ROUTE_PROMPT`: câu cụt mượn chủ đề turn gần nhất; `ai` chung chung không
  DIRECTORY; không tín hiệu cá nhân không DB_ONLY). DB_ONLY oan 25→16 (120b) → 11 (gemma).
* **Thử `gemma4:31b` cho rewrite+route** (`OLLAMA_FAST_MODEL`, code đã hỗ trợ, default
  giữ 120b): 8/8 câu khó spot-check đúng (kể cả `Ký từ bao giờ?`, `Trả khi nào?`),
  0.6–1.2s/call (120b ~1.5–2.5s), output ngắn (25–56 tokens). Full 360 turns:
  0.348→**0.390**, route sạch rõ rệt. Khuyến nghị bật ở prod;
  lưu ý 20b treo endpoint nên con đường model-nhẹ duy nhất hiện tại là gemma.
* Thử thêm few-shots (3 vd câu cụt) vào prompt: 0.390→0.397 (trong nhiễu), DIRECTORY
  1→3 — không hiệu quả, đã revert để prompt gọn. Dừng tuning prompt ở đây.

## Mở rộng 50 conv + full gemma4:31b (2026-10-13)

* Dataset: 50 conv × 12 turns = 600 turns (`memory_internal.csv`, sids 1001–1050).
  20 conv mới (1031–1050, `blueprints/bp5,bp6.json`) bám chunk DB sau ingest mới;
  blueprint dời từ `%TEMP%` vào repo; `build_internal.py` bỏ bắt index-cuối (sửa bug
  merge append nhầm khi thêm file mới), 360 dòng cũ rebuild byte-identical.
* Gold fix: 1003t0 + 1005t8 hết `THIEU THONG TIN` (lấy từ chunk 917 thật);
  1008t8 sửa `ngày vào làm` → `ngày xếp lương liền kề` (An Phát giữ nguyên — đúng tên Cty).
* Model: `OLLAMA_MODEL=gemma4:31b` toàn pipeline (code default + `.env` + `.env.example`).
* Kết quả rewrite (đường prod, gemma): **TỔNG 0.463** (50/50, llm_rewrote 544/600).
  Nhóm cũ (30): ~0.389 — khớp baseline gemma 0.390, ingest mới không regression.
  Nhóm mới (20): ~0.57; cao nhất 1044 (0.91, định mức VPP), 1038 (0.74), 1039 (0.69).
  Thấp nhất 1046 (0.20, giá VPP): mostly thước oan (gold dài `...theo bảng VPP ACT`,
  LLM viết gọn nhưng đủ ý) + 1 lỗi thật (`513 nghìn` gán nhầm sang hộp mực).
* Route: DOC_ONLY 582 / DB_ONLY 12 / DIRECTORY 3 / OUT_OF_SCOPE 3 — sạch.
→ `memory_internal_results.json` (600 turns chi tiết).

## Đáp án end-to-end 20 conv mới (`test_answers.py`, gemma full-main, 2026-10-13)

20 conv × 12 turns qua `POST /chat/query` thật → `memory_answer_20new.json`
(baseline 30 conv giữ ở `memory_answer_baseline30.json`).
Latency: **p50 5.6s / p95 10.3s / max 23.9s**.
Tokens: **in 722.940 / out 21.854 (tổng 744.794), 340 calls**,
TB ~3.012 in + 91 out/turn (turn refused chỉ tốn rewrite ~2k in, không gọi answer).

| Hiện tượng | Số | Ý nghĩa |
|---|---|---|
| Từ chối (`refused`) | **159/240 (66%)** | Bệnh cũ (baseline 71%): T=0.64 gắt, top1 0.3–0.6 rớt hết. Nặng nhất 1043–1046, 1050 (12/12: câu ngắn 214/VPP/giá/cross-doc). |
| Đáp được | 81 turns, overlap TB **0.73** | Đáp được thì khớp gold tốt. Tốt nhất 1049 (1/12 refused, ov 0.72). |
| Review queue (DOC ov<0.4) | 17 turns | Trong JSON, chấm tay như cũ. |
| DB errors | 0 | Sạch. |

## Judge LLM 240 turns 20 conv mới (2026-10-13, `verdicts_20new.json`)

| Verdict | Số |
|---|---|
| ĐÚNG trọng tâm | **55 (23%)** |
| ĐÚNG 1 PHẦN | 11 (thiếu mốc/đối tượng, hoặc hedge 2 tài liệu) |
| SAI | 15 (nhầm tài liệu MWG↔Petrolimex/BLLĐ, lạc đề chunk, neo sai `nó`, nhầm khoản thưởng) + **1 leak SĐT (1038t7, bug PII cũ)** |
| Từ chối oan (đáp án có trong DB) | 159 (66%) |

Đáp được thì đúng 68% (55/81); bệnh chính vẫn là threshold 0.64 + retrieval
không khóa tài liệu (câu ngắn 214/VPP rớt sạch, EVAL_RAG duplicates chen top3).

## Calib threshold trên corpus mới (2026-10-13, `threshold_calib_20new.json`)

30 câu âm viết tay + 238 top1 dương vét từ log (retrieval-only, không LLM).
Âm max 0.667 (thai sản nam — chunk top không chứa đáp án, âm thật),
dương min 0.27. Hai phân bố đè nhau, **không có T sạch**.

| T | Âm lọt | Dương qua (≈refused) |
|---|---|---|
| 0.64 (hiện tại) | 2/30 | 80/238 (≈159 refused, khớp prod) |
| 0.55 | 5/30 | 144/238 (≈94 refused) |
| 0.50 | 10/30 | 168/238 |

Hạ T → nuốt câu âm mà chunk top không có đáp án (vd `Vốn điều lệ PMSC`)
= bịa có trích dẫn. Kết luận: **giữ 0.64**, chữa retrieval (khóa tài liệu,
dọn EVAL_RAG duplicates chen top3, câu truy vấn cho câu ngắn) + đáp mềm
LOW-confidence thay vì refuse cứng.

## Dọn EVAL_RAG + DocLock, chạy lại 20 conv (2026-10-13, `memory_answer_20new_lock.json`)

* Xóa 8 docs `EVAL_RAG|*` (410 chunks duplicate cũ) khỏi DB.
* DocLock (`hybrid_retriever.py`: allowlist mã 214/917/mwg/pmsc/petrolimex/evn/qt/hc/
  act/blld/luong, fail-open khi không có mã, fallback mở khóa khi rỗng).
  Bản rare-token đầu match ồn (`có`→917) nên bỏ, chuyển allowlist.
* Kết quả: refused **159→158**, overlap 0.317→0.326 — gần như không đổi.
  Sửa được 1048t1 (hết nhầm BLLĐ), 1049t9, 1032t6; nhưng lock không nâng điểm
  (1043 khóa đúng 214 mà top1 vẫn 0.3–0.55) nên ngưỡng vẫn là nút thắt.
  Lỗi còn lại: rewrite hay rớt tên doc (1039 không lock → vẫn nhầm),
  nhánh DIRECTORY/PII riêng, rewrite giữa 2 runs không ổn định (1048t3 bịa nghĩa).

## Swap EmbeddingGemma + T=0.66, chạy lại 20 conv (2026-10-13, `memory_answer_20new_gemmaT066.json`)

* Embedder bkai → `google/embeddinggemma-300m` (768d, local, free);
  bake-off 5 cặp: gemma thắng 5/5 (0.37–0.52 vs bkai -0.03–0.47).
* Embed lại 663 chunks + TRUNCATE semantic_cache (vector cũ vô nghĩa).
* Grid trọng số: w=0.7 tốt nhất mọi mức (hạ w chỉ tăng leak).
  T=0.66 (retrieval refused≈63, leak retrieval 9/30).
* Kết quả end-to-end: refused **158→62/240 (66%→26%)**,
  overlap trung bình turn đáp được **0.73→0.80**,
  latency p50 4.6s/p95 8.0s. Review queue 17→12. DB errors 0.
* Giá phải trả (đo end-to-end 30 câu âm ở T=0.66): 3 bịa có trích dẫn
  (lương T13, thai sản nam, họp mấy lần PMSC) + 2 vụ PII nhánh directory.
  Nhánh directory không qua threshold — PII là bug riêng, chưa fix.

## Judge LLM full 178 turns đáp được (2026-10-13, `verdicts_20new_gemmaT066.json`)

| Verdict | Số |
|---|---|
| ĐÚNG trọng tâm | **118 (49% tổng 240)** |
| ĐÚNG 1 PHẦN | 40 (thiếu mốc/đối tượng, hedge 2 doc) |
| SAI | 20 (nhầm tài liệu MWG↔PMSC/214↔917, lạc đề chunk, neo sai, sai quy trình) |
| Từ chối oan | 62 (26%) |

So với run cũ: hết leak PII (1038t7, 1036t3 đã đúng), nhưng nhầm tài liệu
vẫn là bệnh lớn nhất khi rewrite rớt tên doc (1039). Không còn SAI+PII run này.

## Fix code: rewrite giữ tên doc + band mềm + judge full (2026-10-13)

* `router.py`: rewrite GIỮ tên/mã tài liệu → doc-lock bắn trúng, hết nhầm doc
  kiểu 1039 (MWG↔PMSC).
* `chat_service.py` (2 đường query/stream): band mềm top1 [0.50, 0.66) →
  đáp + cờ LOW + prefix cảnh báo + không cache; dưới 0.50 từ chối như cũ.
  Reranker-score làm gate đã đo và loại (điểm dồn về 0, T ảo).
* `memory_answer_20new_softband.json`: refused **62→7/240**,
  leak end-to-end giữ nguyên 10/30 cùng set (band không rò thêm).
* Judge tay full 233 turns (`verdicts_20new_softband.json`, checker key đủ):

| Verdict | Số |
|---|---|
| ĐÚNG trọng tâm | **156 (65%)** |
| ĐÚNG 1 PHẦN | 55 (thiếu mốc/đối tượng, hedge 2 doc) |
| SAI | 22 (nhầm doc khi rewrite rớt tên, lạc đề chunk, neo sai) |
| Từ chối oan | 7 (top1 < 0.50, giữ lại đúng thiết kế) |

## Bỏ DocLock + prompt đầy đủ chi tiết, chạy lại (2026-10-13, `memory_answer_20new_nolock.json`)

* Gỡ DocLock (chatbot thật không chọn doc trước); giữ rewrite-giữ-tên-doc + bonus.
* Prompt đáp án thêm 2 luật: liệt kê HẾT mốc số/thời hạn/điều kiện (12),
  ưu tiên tài liệu đang bàn (13).
* Kết quả: refused 7→8 (nhiễu), overlap TB tăng mạnh (1046: 0.22→0.68).
* Chấm lại 55 partials cũ: **14 flips thành ĐÚNG** (1032t1/t2/t11, 1033t9,
  1037t9, 1038t9, 1039t1, 1041t5/t7, 1042t8, 1044t8, 1046t4/t9, 1049t0),
  ~39 vẫn thiếu chi tiết phụ, 1 rớt xuống SAI (1039t7 nhầm doc),
  1 bị refused do nhiễu run (1050t3).
* 7-8 refused cuối: 3 rewrite hỏng (1037t10, 1039t8, 1050t2 — LLM đổi nghĩa
  câu hỏi, code không cứu được), 2 ranking sai doc (1049t8 BLLĐ>Maub,
  1037t10 EVN — cần doc-tracking đã bỏ), 1 recall số (1046t10 true chunk
  ngoài top-40), 1 biên (1040t1 top1 0.46 < floor 0.50, hạ floor rước rác).

## Judge LLM full run nolock (2026-10-13, `verdicts_20new_nolock.json`, checker đủ key)

| Verdict 240 turns | Số |
|---|---|
| ĐÚNG trọng tâm | **161 (67%)** |
| ĐÚNG 1 PHẦN | 54 (thiếu mốc phụ, hedge 2 doc) |
| SAI | 17 (nhầm doc khi rewrite rớt tên, lạc chunk, neo sai) |
| Từ chối oan | 8 (top1 < 0.50) |

So với run softband (156/55/22/7): +5 đúng, −5 sai, refused tương đương.
Không còn SAI+PII. Prompt đầy đủ-chi-tiết + ưu tiên-doc-conv là thay đổi
có ích nhất (14 partials cũ flip đúng).

## Fix số thập phân lexical + retry-rewrite (2026-10-13)

* Bug: query tách "809.091"→"809"+"091" nhưng tsv giữ lexeme nguyên →
  số thập phân không bao giờ khớp lexical. Fix: UNION thêm dạng gốc
  (`[0-9]+[.][0-9.]*[0-9]+`, chỉ số.chấm.số cho an toàn to_tsquery).
  Verify: "809.091..." top1 rớt top-40 → 0.53 đúng doc.
* Retry: turn rớt sàn viết lại 1 lần (note giữ tên doc/chi tiết), giữ bản
  điểm cao hơn. Chỉ tốn thêm 1 call khi rớt sàn; rớt tiếp thì chịu.
* Đo trên 7 convs chứa turns rớt: 5 refused tồn tại nhưng ĐỔI THÀNH PHẦN
  (1039t6, 1040t1 convert; 1037t2, 1045t6 regress do rewrite đổi giữa runs
  — verify rewrite cũ vẫn đậu 0.78/0.65 nên không phải code).
  Kết luận: đuôi 7-8 turns nằm trong nhiễu LLM (±0.05), không còn fix
  xác định bằng code. Ba nhóm còn lại: rewrite bịa nghĩa (cần model/
  few-shot tốt hơn), ranking sai doc (cần doc-tracking), recall số (đã fix).

## Chạy lại

```bash
cd ai-service
python tests/memory/internal/test_memory_sessions.py
# Sửa đáp án/conv: sửa blueprint TEMP/bp*.json rồi python tests/memory/build_internal.py
```

## Đáp án multi-turn end-to-end (`test_answers.py`, gemma full-main, 2026-10-12)

30 conv × 12 turns qua `POST /chat/query` thật (user seed thật), 360 turns.
→ `memory_answer_results.json`. Latency: **p50 3.3s / p95 6.3s / max 16.8s**.

| Hiện tượng | Số | Ý nghĩa |
|---|---|---|
| Từ chối câu legit (`refused`) | **254/360 (71%)** | T=0.64 quá gắt trên câu nội bộ dài: top1 0.3–0.6 rớt hết. Giá của an toàn đã đo được. |
| Đáp án DOC (không từ chối) | 91 turns, overlap TB 0.63 | Đáp được thì nội dung khớp gold khá. |
| Đáp án DB cá nhân hóa | ~15 turns | Đúng người, cần chấm riêng (không so gold doc). |
| Route oan giá cả → OUT_OF_SCOPE | cả conv 1012 (Casio, thước, bút...) | Khớp lỗi đã biết (DOC→OOS 17 ca): câu hỏi giá trong tài liệu bị từ chối sai lý do. |
| Cá nhân hóa đè câu tài liệu | vd 1006t9 hỏi "có phụ cấp gì" → đáp "phụ cấp của bạn 0 đồng" | Route DB trên câu mơ hồ → đáp đúng người, sai ý hỏi. |
| **Rò rỉ SĐT qua danh bạ** | vd 1014t10 `Ai trình quy chế này?` → trả 5 nhân viên kèm SĐT | Từ "Ai" không tên riêng vẫn lọt nhánh directory search. **Bug PII, phải fix trước prod.** |
| Rewrite bịa chi tiết | `Bảng lương 1-8/2026`, `Điều 3`, số lương 15tr nhét vào rewrite | Router tự thêm cụ thể không có trong câu hỏi. |

Hàng chờ review tay: 17 turns DOC overlap<0.4 trong JSON. Đáp án đúng mẫu (1003t0 các bước
đăng ký xe, trích số hiệu + ngày) cho thấy pipeline chạy tốt khi top1 đủ cao.

## Judge tay 32 câu (2026-10-12, thay code chấm — `verdicts_32.json`)

Mình đọc Q + gold + đáp án + trích dẫn, chấm từng câu (17 overlap thấp + 15 overlap cao đối chứng):

| Verdict | Số | Gồm |
|---|---|---|
| ĐÚNG | 22 | Kể cả câu overlap 0 mà đáp án đầy đủ hơn gold |
| ĐÚNG 1 PHẦN | 4 | Thiếu căn cứ / chỉ nói 1 vế |
| SAI | 3 | Route oan giá (1012t0), rớt directory (1018t4), lạc đề tăng ca vs thù lao (1024t5) |
| NGHI (gold/blueprint) | 3 | 2 gold `THIEU THONG TIN`, 1 gold có thể sai (1008t8 thâm niên), 1 mâu thuẫn HĐQT vs HDTV cần đối chiếu chunk |

Kết luận: trong 17 câu overlap thấp, chỉ ~3-4 sai thật — còn lại thước oan.
Lỗi thật gom đúng 3 pattern đã biết (route oan, directory, lạc đề), không phát hiện
bệnh mới. 15/15 câu overlap cao đều đúng → overlap cao là tín hiệu tốt, overlap
thấp phải đọc tay (không phải auto-fail).
