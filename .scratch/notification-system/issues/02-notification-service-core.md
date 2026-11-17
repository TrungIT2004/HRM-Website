# 02: Backend NotificationService Core

**What to build:** `NotificationService` with `createAndPush(NotificationEvent)` (annotated `@TransactionalEventListener(phase = AFTER_COMMIT)`), `getForUser(UUID, Pageable, type, readStatus)`, `getUnreadCount(UUID)`, `markRead(UUID, UUID)`, `markAllRead(UUID)`. Uses `SimpMessagingTemplate.convertAndSendToUser(userId, "/queue/notifications", message)` for realtime push. Unit tests mocking repository and messaging template.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Create `NotificationService` with constructor-injected `NotificationRepository`, `SimpMessagingTemplate`, `ApplicationEventPublisher`
- [ ] Implement `createAndPush(NotificationEvent)` — persist `Notification` entity, then push `NotificationMessage` (type=NOTIFICATION_CREATED, payload) via `SimpMessagingTemplate`
- [ ] Implement `getForUser()` with pagination, optional type filter, optional readStatus filter (UNREAD/READ/ALL), ordered by `created_at DESC`
- [ ] Implement `getUnreadCount()` using partial index (WHERE read_at IS NULL)
- [ ] Implement `markRead()` and `markAllRead()` updating `read_at = NOW()`
- [ ] Write `NotificationServiceTest` (JUnit + Mockito): verify persist + push on createAndPush; verify query methods
- [ ] Verify: unit tests pass (`./mvnw test -Dtest=NotificationServiceTest`)