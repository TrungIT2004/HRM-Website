# 12: E2E Smoke Test & Polish

**What to build:** Manual end-to-end verification of complete notification flows. Fix race conditions, timing issues, reconnection edge cases, UI polish.

**Blocked by:** 04, 05, 11

**Status:** ready-for-agent

- [ ] Test flow 1 (Approver gets notification):
  - Browser 1: Login as manager/HR (approver)
  - Browser 2: Login as employee, create leave request
  - Verify Browser 1: toast appears (bottom-right), bell badge = 1, dropdown shows notification with correct title/body/time, click → navigates to leave detail page, badge clears
- [ ] Test flow 2 (Requestor gets status update):
  - Browser 1: Login as employee (requestor)
  - Browser 2: Login as approver, approve/reject the leave request
  - Verify Browser 1: toast appears, bell badge increments, dropdown shows "Đơn nghỉ phép đã được duyệt/từ chối", click → navigates to my leave requests
- [ ] Test flow 3 (Tab in background):
  - Browser 1: Login, switch to another tab
  - Trigger notification (create request as another user)
  - Verify: document title shows `(1) ACT HRM`
  - Switch back to tab: title restores to `ACT HRM`
- [ ] Test flow 4 (Notifications page):
  - Visit `/notifications`
  - Verify: pagination (10/page), tabs (All/Unread/Read), filter chips (5 types), table renders correctly
  - Click "Mark all as read" → badge clears, all items show Read status
  - Click row → navigates to detail
- [ ] Test flow 5 (Reconnection):
  - Login, wait for WS connect
  - Simulate network disconnect (DevTools → Offline)
  - Re-enable network → verify WS reconnects, notifications still work
  - Login with different user in same browser → verify WS reconnects with new token
- [ ] Fix any issues found: race conditions (markRead called before navigation), toast timing, dropdown positioning on mobile, TypeScript errors, console warnings
- [ ] Verify: `npm run build` passes, `npm run lint` passes