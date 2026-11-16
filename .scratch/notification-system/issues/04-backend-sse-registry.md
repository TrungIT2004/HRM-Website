# 04: Backend - SSE Emitter Registry

**What to build:** Create a thread-safe registry for managing Server-Sent Events connections per user, with methods to add/remove emitters, broadcast events to specific users, and send periodic heartbeats.

**Blocked by:** 03-backend-entity-repo

**Status:** ready-for-agent

- [ ] Create `SseEmitterRegistry.java` with `ConcurrentHashMap<UUID, List<SseEmitter>>`
- [ ] Method: `addEmitter(UUID userId, SseEmitter emitter)` - register new connection
- [ ] Method: `removeEmitter(UUID userId, SseEmitter emitter)` - cleanup on disconnect
- [ ] Method: `broadcastToUser(UUID userId, Object event)` - send event to all user's connections
- [ ] Method: `broadcastUnreadCount(UUID userId)` - send unread count update
- [ ] Scheduled task: send `heartbeat` event every 30 seconds to all active connections
- [ ] Handle emitter completion/timeout cleanup automatically