# 11: Frontend Navbar + AppShell Integration

**What to build:** Integrate notification components into app shell. `Navbar.tsx`: add `<NotificationBell />` left of user avatar (between Quick Punch and user dropdown). `AppShell.tsx`: wrap children with `<NotificationProvider>`, render `<NotificationToasts />` at root. `services/authService.ts`: on login success, dispatch custom event `act-hrm:token-changed` (or call context refresh); on logout, dispatch `act-hrm:logout` to trigger WS disconnect.

**Blocked by:** 08, 09

**Status:** ready-for-agent

- [ ] Modify `Navbar.tsx`:
  - Import `NotificationBell` from `@/components/layout/NotificationBell`
  - In right section (before user dropdown), add `<NotificationBell />`
  - Ensure responsive: on mobile, bell icon still visible (maybe hide quick punch if needed)
- [ ] Modify `AppShell.tsx`:
  - Import `NotificationProvider` and `NotificationToasts`
  - Wrap `{children}` with `<NotificationProvider><NotificationToasts />{children}</NotificationProvider>`
- [ ] Modify `services/authService.ts`:
  - In `login()`: after storing token, `window.dispatchEvent(new CustomEvent('act-hrm:token-changed'))`
  - In `logout()`: before clearing token, `window.dispatchEvent(new CustomEvent('act-hrm:logout'))`
- [ ] Update `useNotificationsWebSocket.ts` to listen for these events and reconnect/disconnect
- [ ] Verify: login → WS connects, bell shows; create notification → toast + badge + dropdown; logout → WS disconnects, bell empty