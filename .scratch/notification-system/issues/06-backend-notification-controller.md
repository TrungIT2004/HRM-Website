# 06: Backend - NotificationController (REST + SSE Endpoints)

**What to build:** Create the REST controller exposing SSE stream endpoint and REST fallback endpoints for notifications list, unread count, and mark-read operations.

**Blocked by:** 05-backend-notification-service

**Status:** ready-for-agent

- [ ] Create `NotificationController.java` with `@RestController @RequestMapping("/api/notifications")`
- [ ] `GET /stream` - returns `SseEmitter`, produces `text/event-stream`
  - Auth via JWT from Authorization header (reuse existing pattern)
  - Register emitter in `SseEmitterRegistry` on connect
  - Send initial `unread_count` event on connect
  - Cleanup on completion/timeout
- [ ] `GET /` - paginated list with `page`, `size`, `unreadOnly` params
  - Returns `PageResponse<NotificationDTO>`
- [ ] `GET /unread-count` - returns `{ count: number }`
- [ ] `PATCH /{id}/read` - mark single notification as read
- [ ] `PATCH /read-all` - mark all notifications as read
- [ ] Events emitted via SSE: `notification`, `unread_count`, `heartbeat`