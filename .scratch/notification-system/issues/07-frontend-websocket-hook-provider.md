# 07: Frontend WebSocket Hook + Provider

**What to build:** `hooks/useNotificationsWebSocket.ts` using `@stomp/stompjs` — connects on auth (token from localStorage), subscribes to `/user/queue/notifications`, maintains latest 4 notifications for dropdown, exposes `unreadCount`, `markRead(id)`, `markAllRead()`, `fetchPage(page, filters)`. `components/providers/NotificationProvider.tsx` context provider wrapping app. Handles reconnection on token change (listens to auth events).

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] Install `@stomp/stompjs` (`npm install @stomp/stompjs`)
- [ ] Create `hooks/useNotificationsWebSocket.ts`:
  - `useEffect` on mount: read `act_hrm_access_token` from localStorage, create `Client` with `brokerURL: '/ws/notifications'`, `connectHeaders: { Authorization: \`Bearer \${token}\` }`, `reconnectDelay: 5000`, `heartbeatIncoming: 10000`, `heartbeatOutgoing: 10000`
  - `onConnect`: subscribe to `/user/queue/notifications`, handle `NOTIFICATION_CREATED` → prepend to `notifications[]` (max 4 for dropdown), increment `unreadCount`; handle `UNREAD_COUNT` → set `unreadCount`
  - Expose: `notifications` (latest 4), `unreadCount`, `markRead(id)` → PATCH API + local state update, `markAllRead()` → PATCH API + local state update, `fetchPage(page, filters)` → GET API
  - Cleanup on unmount: `client.deactivate()`
  - Reconnection: watch `authService` token changes (custom event or context), reconnect with new token
- [ ] Create `components/providers/NotificationProvider.tsx`:
  - Context: `{ notifications, unreadCount, markRead, markAllRead, fetchPage, refresh }`
  - Wraps children, uses `useNotificationsWebSocket` internally
- [ ] Verify: dev server starts (`npm run dev`), no console errors, WebSocket connects in Network tab