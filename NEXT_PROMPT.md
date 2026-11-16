# Next Session Prompt — Implement Tickets 17-18

## Context
Tickets 07-16 complete (backend notification integration + unit tests passing). Frontend components (tickets 09-15) already implemented in prior session. Remaining:

- **Ticket 17**: Frontend unit tests for NotificationContext, NotificationBell, ToastContainer
- **Ticket 18**: E2E Playwright test (create leave → approve → verify toast + bell)

## Prompt for Next Session

```
/mattpocock-skills:implement-spec Continue implementing the real-time notification system per SPEC_NOTIFICATION_SYSTEM.md.

Tickets 07-16 are complete:
- 07: LeaveService integration ✅
- 08: OvertimeService integration ✅
- 09: Frontend types + API client ✅
- 10: NotificationContext (SSE client) ✅
- 11: AppShell + AuthContext integration ✅
- 12: ToastContainer ✅
- 13: NotificationBell ✅
- 14: TabBadge ✅
- 15: Navbar integration ✅
- 16: Backend unit tests (NotificationServiceTest) ✅ — 11/11 passing

Now implement tickets 17-18:

▎ 17: Frontend unit tests for NotificationContext, NotificationBell, ToastContainer
  - Set up Jest + React Testing Library in HRM Website/
  - Test SSE connection lifecycle (connect/disconnect/reconnect)
  - Test toast queue: add, auto-dismiss 5s, click→mark read+navigate
  - Test NotificationBell: badge count, dropdown render, mark all read, pagination
  - Test TabBadge: document.title/favicon updates on unread count change

▎ 18: E2E Playwright test (create leave → approve → verify toast + bell)
  - Set up Playwright in HRM Website/
  - Test flow: login as staff → create leave request → login as manager → approve → verify toast appears + bell badge increments
  - Run against running dev servers (frontend: npm run dev, backend: ./mvnw spring-boot:run)

Run tests after each phase:
- Frontend unit: npm test (in HRM Website/)
- E2E: npx playwright test (in HRM Website/)

Key patterns to follow:
- Existing test setup patterns if any (check package.json, config files)
- Use React Testing Library for component tests
- Playwright: page.goto, fill, click, expect(locator).toContainText
- SSE testing: mock EventSource or use MSW for API mocking
- Authentication via existing apiClient (credentials: 'include')

Reference: SESSION_HANDOFF.md for current state
```










<!-- 
Continue implementing the real-time notification system per SPEC_NOTIFICATION_SYSTEM.md.

**Current State**: Ticket 17 (Frontend unit tests) is ~75% complete. 37/50 tests passing.

**Test Results**:
- ToastContainer: 13/15 passing (2 failing - test buttons not found)
- NotificationBell: 16/21 passing (5 failing - dropdown text timing)
- NotificationContext: ~8/21 passing (act() warnings from SSE/async)
- TabBadge: Skipped (favicon mock issue)

**Files Modified**:
- `jest.setup.ts` - localStorage/EventSource/canvas mocks
- `src/context/NotificationContext.test.tsx` - deferred promises, act() wrapping
- `src/components/ui/ToastContainer.test.tsx` - test setup
- `src/components/layout/NotificationBell.test.tsx` - test scenarios
- `src/components/ui/TabBadge.test.tsx` - simplified favicon tests

**To Resume**:
1. Fix remaining unit test failures (act() warnings, timing issues)
2. Then implement Ticket 18: E2E Playwright test
   - `npx playwright install`
   - Write test: login staff → create leave → login manager → approve → verify toast+bell
   - Run against dev servers (npm run dev + ./mvnw spring-boot:run)

**Run Commands**:
- Unit: `cd "HRM Website" && npm test`
- E2E: `cd "HRM Website" && npx playwright test`

Key patterns: Use React Testing Library, jest fake timers, mock apiClient + EventSource globally in jest.setup.ts -->







<!-- Update the actual .env file with the Flash-Lite model configuration, then run the full evaluation pipeline:

1. Edit C:\Users\ad\Desktop\HRM\ai-service\.env to include:
   GEMINI_MODEL_ROUTE=gemini-3.5-flash-lite
   GEMINI_MODEL_SQL=gemini-3.5-flash-lite
   GEMINI_MODEL_ANS=gemini-3.5-flash-lite
   GEMINI_OCR_MODEL=gemini-3.5-flash-lite
   GEMINI_RPM_ROUTE=15
   GEMINI_RPM_SQL=15
   GEMINI_RPM_ANS=15

2. Wait for quota reset (08:00 UTC / 15:00 ICT) - check quota_state.json day_start timestamps

3. Clear cached predictions: rm test_v2/text2sql/benchmarks/results/hrm_db_only-predictions.json

4. Run full evaluation sequence:
   python -m test_v2.text2sql.run_hrm_evaluation_fixed
   python -m test_v2.db_only.retrieval.eval_db_generation
   python -m test_v2.hybrid.eval_hybrid

Target: Text2SQL EX ≥85%, DB Generation sql_ok ≥90%, Hybrid has_doc_facts ≥50%

--- -->