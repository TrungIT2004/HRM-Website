# 11: Frontend - Wrap AppShell with NotificationProvider & Auth Integration

**What to build:** Modify AppShell to wrap children with NotificationProvider, and update AuthContext to connect/disconnect SSE on login/logout.

**Blocked by:** 10-frontend-notification-context

**Status:** ready-for-agent

- [ ] Modify `HRM Website/src/components/layout/AppShell.tsx`:
  - Import `NotificationProvider`
  - Wrap `{children}` with `<NotificationProvider>`
- [ ] Modify `HRM Website/src/context/AuthContext.tsx`:
  - Import `useNotifications` hook
  - In `login()`: call `connect()` after successful login
  - In `logout()`: call `disconnect()` before clearing user
  - In `switchUser()`: call `disconnect()` then `connect()` for new user
- [ ] Feature flag: Check `NEXT_PUBLIC_ENABLE_NOTIFICATIONS` before connecting