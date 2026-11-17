# 03: Backend REST API Endpoints

**What to build:** `NotificationController` exposing 5 endpoints: `GET /api/notifications` (paginated, filtered by type/readStatus), `GET /api/notifications/unread-count`, `PATCH /api/notifications/{id}/read`, `PATCH /api/notifications/read-all`, `GET /api/notifications/{id}`. All endpoints extract `userId` from JWT via `RequestContextHolder`. `@WebMvcTest` slice tests.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Create `NotificationController` with `@RestController`, `@RequestMapping("/api/notifications")`
- [ ] `GET /` — delegate to `NotificationService.getForUser()`, return `Page<NotificationResponse>` (map entity → DTO)
- [ ] `GET /unread-count` — delegate to `NotificationService.getUnreadCount()`, return `{ "count": N }`
- [ ] `PATCH /{id}/read` — delegate to `NotificationService.markRead()`, return 204
- [ ] `PATCH /read-all` — delegate to `NotificationService.markAllRead()`, return 204
- [ ] `GET /{id}` — fetch single notification (verify ownership), return `NotificationResponse`
- [ ] Write `NotificationControllerTest` (`@WebMvcTest`): test pagination, filters, mark-read, unauthorized access returns 401/403
- [ ] Verify: slice tests pass (`./mvnw test -Dtest=NotificationControllerTest`)