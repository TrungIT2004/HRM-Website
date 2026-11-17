# 06: Frontend Types + API Client

**What to build:** Add notification types to `types/index.ts` and create `services/notificationService.ts` wrapping all 5 REST endpoints.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Add to `types/index.ts`:
  - `NotificationType = 'LEAVE' | 'OVERTIME' | 'RESIGNATION' | 'ASSET' | 'IT_TICKET'`
  - `NotificationPriority = 'HIGH' | 'NORMAL'`
  - `NotificationReferenceType = 'LEAVE_REQUEST' | 'OVERTIME_RECORD' | 'RESIGNATION_REQUEST' | 'ASSET_REQUEST' | 'IT_TICKET'`
  - `Notification` interface (notificationId, type, title, body, referenceId, referenceType, priority, metadata, readAt, createdAt)
  - `NotificationPage` interface (content[], totalElements, totalPages, size, number)
- [ ] Create `services/notificationService.ts` using existing `apiClient` pattern:
  - `getNotifications(params: { page?, size?, type?, readStatus? })` → `Promise<NotificationPage>`
  - `getUnreadCount()` → `Promise<{ count: number }>`
  - `markRead(notificationId: string)` → `Promise<void>`
  - `markAllRead()` → `Promise<void>`
  - `getNotification(notificationId: string)` → `Promise<Notification>`
- [ ] Verify: TypeScript compiles (`npm run build` in HRM Website)