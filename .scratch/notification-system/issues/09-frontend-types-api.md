# 09: Frontend - TypeScript Types & API Client Methods

**What to build:** Add notification-related TypeScript interfaces to types/index.ts and extend apiClient.ts with notification API methods.

**Blocked by:** 08-integrate-overtime-service

**Status:** ready-for-agent

- [ ] Add to `HRM Website/src/types/index.ts`:
  - `NotificationType`, `NotificationAction`, `NotificationPriority` type unions
  - `Notification` interface (notificationId, recipientId, senderId, requestType, requestId, action, title, message, priority, metadata, isRead, isSeen, createdAt, updatedAt)
  - `ToastNotification` interface (id, notification, dismiss)
- [ ] Add to `HRM Website/src/services/apiClient.ts`:
  - `notificationApi.getNotifications(params)` - GET /api/notifications
  - `notificationApi.getUnreadCount()` - GET /api/notifications/unread-count
  - `notificationApi.markRead(id)` - PATCH /api/notifications/{id}/read
  - `notificationApi.markAllRead()` - PATCH /api/notifications/read-all
- [ ] Reuse existing `PageResponse<T>` and `ApiError` patterns