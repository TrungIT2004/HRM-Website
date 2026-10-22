# Kết quả test Token Usage (đo 2026-10-12, log usage provider thật)

Tool: `tokens.py` (monkeypatch đếm, không sửa prod). Đã log sẵn trong prod
(`[LLM usage]` ở `_llm_complete`/`_generate_llm_answer`). Chạy: `py tests/tokens/tokens.py`.

| Loại turn | LLM calls | In | Out |
|---|---|---|---|
| DOC | ~3 (route + answer + title lẻ) | ~5.4k | ~0.45k |
| DB | ~4 (route + text2sql ×2 + answer) | ~16.5k | ~0.8k |

Đầu tốn nhất: schema + few-shots text2sql (~6k/call). KHÔNG cắt schema —
thí nghiệm cũ ghi trong code: prompt ngắn → SQL tệ hơn + retry ×2.5.
Giảm tiền đúng cách: bật prompt-caching phía provider.
