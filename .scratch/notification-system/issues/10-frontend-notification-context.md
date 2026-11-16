# 10: Frontend - NotificationContext (SSE Client)

**What to build:** Create a React Context that manages SSE connection, notification state, unread count, and toast queue. Handles auto-reconnection and REST fallback on reconnect.

**Blocked by:** 09-frontend-types-api

**Status:** ready-for-agent

- [ ] Create `HRM Website/src/context/NotificationContext.tsx`
- [ ] State: `notifications: Notification[]`, `unreadCount: number`, `eventSource: EventSource | null`, `toasts: ToastNotification[]`
- [ ] `connect()`: Open EventSource to `/api/notifications/stream` with JWT auth
  - Handle `notification` event: prepend to notifications, increment unreadCount, pushToast()
  - Handle `unread_count` event: update unreadCount
  - Handle `heartbeat`: keep alive (native EventSource handles reconnection)
- [ ] `disconnect()`: Close EventSource
- [ ] `markRead(id)`: Optimistic update + API call
- [ ] `markAllRead()`: Batch update + API call
- [ ] `pushToast(notification)`: Add to toast queue, auto-dismiss after 5s
- [ ] `dismissToast(id)`: Remove from toast queue
- [ ] On reconnect: fetch missed notifications via REST (last 20 + unread count)
- [ ] Persist `unreadCount` to `localStorage` for tab badge on reload
- [ ] Export `NotificationProvider` and `useNotifications()` hook