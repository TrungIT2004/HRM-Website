# 01: Backend WebSocket Infrastructure & DB Schema

**What to build:** STOMP WebSocket endpoint at `/ws/notifications` with JWT handshake authentication, simple in-memory message broker (`/queue`, `/topic`), `Notification` JPA entity mapped to PostgreSQL `notifications` table (auto-created via `ddl-auto=update`), `NotificationRepository`, and `NotificationEvent` POJO for event-driven triggers.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Add `spring-boot-starter-websocket`, `spring-messaging`, `hibernate-types-60` dependencies to `pom.xml`
- [ ] Create `WebSocketConfig` with `@EnableWebSocketMessageBroker`, simple broker, `/app` prefix, `/user` prefix, custom `HandshakeInterceptor` extracting JWT from `Authorization` header and validating via `JwtService`
- [ ] Create `Notification` entity (`notification_id` UUID PK, `user_id` FK → users, `type`, `title`, `body`, `reference_id`, `reference_type`, `priority`, `metadata` JSONB, `read_at`, `created_at`) with partial index on unread and composite index on user+created_at
- [ ] Create `NotificationRepository` extending `JpaRepository<Notification, UUID>` with custom queries for pagination + filters
- [ ] Create `NotificationEvent` POJO carrying: recipientUserId, type, title, body, referenceId, referenceType, priority, metadata Map
- [ ] Verify: `mvn spring-boot:run` starts without error, `notifications` table created in PostgreSQL, WS handshake succeeds with valid JWT