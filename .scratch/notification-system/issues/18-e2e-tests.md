# 18: E2E Tests - Full Notification Flow (Playwright)

**What to build:** End-to-end Playwright tests covering the complete notification flow: create request → approve → verify toast + bell update, background tab behavior, and network reconnection.

**Blocked by:** 17-frontend-unit-tests

**Status:** ready-for-agent

- [ ] Create `tests/notification-flow.spec.ts`:
  - Test: Employee submits leave request → Manager sees toast "New leave request from [Name]" within 2s, bell badge increments
  - Test: Manager approves leave → Employee sees toast "Leave Request Approved" within 2s, bell badge increments
  - Test: Page reload → Bell badge shows correct unread count from DB, dropdown shows full history
  - Test: Tab in background → Browser title shows "(3) ACT HRM", favicon shows red badge with "3"
  - Test: Network disconnect/reconnect → SSE auto-reconnects, missed notifications fetched via REST on reconnect
  - Test: Mark as read → Badge decrements immediately, notification moves to "read" section in dropdown
  - Test: All request types (Leave, Overtime) produce correct notifications
  - Use existing test users (`MOCK_USERS` in frontend, seeded DB in backend)
  - Follow `CHATBOT_TEST_REPORT.md` pattern