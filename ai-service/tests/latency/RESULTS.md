# Kết quả test Latency (đo 2026-10-12)

Tool: `breakdown.py` (spy stages, không sửa prod) + `ttft.py` (TTFT stream).
User thật đã seed cho câu DB. Chạy: `py tests/latency/breakdown.py`.

## Breakdown/turn (giây)

| Loại | Tổng | Viết lại + route | Retrieve (rerank) | Sinh đáp án |
|---|---|---|---|---|
| DOC đáp được | 5–8 | 1.3–2.5 | 1.2–3.0 (0.6–1.1) | 2.3–2.6 |
| DOC bị từ chối | 2.4–3 | 1.3–2.3 | 0.4–0.6 | 0 (bỏ qua) |
| DB | 3.6–6.9 | 1.2–1.7 | — (+text2sql 1–2) | 0.9–3.6 |
| Cache-hit | 1.8 | 1.1 | 0 | 0 |

Rẻ nhất có thể: check cache TRƯỚC khi viết lại (tiết kiệm ~1.1s) — chưa làm.

## Concurrent: khóa nằm ở provider, không phải code (`load_breakdown.py`)

Cùng 3 câu, tuần tự vs 3 threads (1 ChatService chung như prod):

| Stage | Tuần tự (3 req) | Song song x3 | Tỉ lệ |
|---|---|---|---|
| LLM (rewrite+...) | 9.0s | 12.6s | **1.4x phồng** |
| LLM answer | 4.4s | 4.9s | ~1.0x |
| retrieve / rerank / embed | 5.5 / 2.3 / 0.3s | 5.4 / 2.1 / 1.1s | phẳng (embed/cache tăng tuyệt đối nhỏ) |

LLM phồng, local phẳng → provider cloud bóp concurrent trên các call lớn
(probe 5 calls nhỏ thì overlap tốt). GPU/DB oan — đã được minh oan.
Thực tế: ~2–3 concurrent là trần êm trên box này; hơn nữa thì provider xếp hàng.

## Prefill/decode

Không đo được: API không trả timing; thử stream thì server dồn token xả cuối
(TTFT = total). Muốn số này phải đổi đường stream, để sau.
