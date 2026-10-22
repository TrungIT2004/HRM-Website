# Kết quả test Stress + chịu lỗi (đo 2026-10-12)

Tool: `stress.py` (50 req), `stress3.py` (so 3 vs 10 concurrent), `prov.py`
(provider có song song không), `drill.py` (ngắt LLM). Server phải mở tay:
`py -m uvicorn main:app --host 127.0.0.1 --port 8000` (TẮT server xong kill
theo command-line, đừng kill theo PID launcher — con worker mồ côi giữ port).

## Concurrent (uvicorn workers=1, config prod hiện tại)

| Mức | wall 15 req | p50 | Kết luận |
|---|---|---|---|
| 3 | 64s | 12.1s | Parallelism hiệu dụng ≈ 1 |
| 10 | 72s | 28.5s | Không scale |

50 req lần đầu: 50/50 OK, p50 37.5s (đơn luồng 4.2s). Đã loại trừ: DB pool (20 conns),
provider throttle (5 calls song song wall≈max), rate limit app (không có).
Nghi phạm đã chốt bằng `latency/load_breakdown.py` (so stage tuần tự vs x3):
LLM phồng 1.4x, retrieve/rerank phẳng, DB pool OK → **cloud bóp concurrent
trên calls lớn**, GPU/DB minh oan. workers=2 trên máy dev 6GB VRAM TỆ HƠN
(p50 69s, thrash) — đã revert Dockerfile. Tune workers trên máy giống prod
(container torch CPU) rồi đo lại.

## LLM chết (`drill.py`: chặn cả 2 provider)

5/5 HTTP 200, route rớt keyword_fallback, đáp án báo bận trung thực, injection
vẫn chặn. Giá: 22–32s mới báo bận → đã thêm `timeout=60` cả 2 client.
