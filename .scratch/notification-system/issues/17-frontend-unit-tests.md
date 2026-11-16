# 17: Frontend - Unit Tests for NotificationContext & UI Components

**What to build:** Unit tests for NotificationContext, NotificationBell, and ToastContainer using React Testing Library.

**Blocked by:** 16-backend-unit-tests

**Status:** ready-for-agent

- [ ] Create `NotificationContext.test.tsx`:
  - Mock EventSource, verify state updates on message events
  - Test connect()/disconnect()
  - Test markRead(id) - optimistic update + API call
  - Test markAllRead() - batch update + API call
  - Test pushToast/dismissToast
  - Follow `AuthContext.test.tsx` pattern
- [ ] Create `NotificationBell.test.tsx`:
  - Render badge with correct unread count
  - Dropdown opens on click, shows notifications
  - Mark as read updates UI
  - Follow `Navbar.test.tsx` pattern
- [ ] Create `ToastContainer.test.tsx`:
  - Stacks multiple toasts vertically
  - Auto-dismisses after 5s
  - Click navigates to request detail
  - Color coding by action type