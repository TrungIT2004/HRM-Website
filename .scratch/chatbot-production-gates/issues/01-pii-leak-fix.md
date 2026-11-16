# 01: PII Leak Fix — directory_lines() Sanitization

**What to build:**
Remove phone numbers (SĐT) from employee directory lookup results returned in chat responses. The `directory_lines()` function currently includes `SĐT: {phone}` in its output, leaking PII. After this fix, directory lookups return only name, department, job title, and email.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `directory_lines()` output never contains "SĐT" or phone number regex pattern
- [ ] Unit test passes: `tests/sql/test_executor.py::test_directory_lines_no_phone`
- [ ] No regression: existing callers (chat_service, DB retrieval tests) still work
- [ ] Manual verification: ask chatbot "Who is [colleague]?" — response shows name/dept/title/email only