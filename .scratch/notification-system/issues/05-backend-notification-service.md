# 05: Backend - NotificationService (Central Emitter)

**What to build:** Create the core NotificationService that all request services call to emit notifications. Handles recipient resolution logic based on action type and persists notifications to DB while pushing real-time via SSE.

**Blocked by:** 04-backend-sse-registry

**Status:** ready-for-agent

- [ ] Create `NotificationService.java` with `@Service @RequiredArgsConstructor`
- [ ] Inject: `NotificationRepository`, `UserRepository`, `SseEmitterRegistry`
- [ ] Method: `emit(UUID recipientId, NotificationEvent event)` - persist + push via SSE
- [ ] Method: `emitToRole(String role, NotificationEvent event)` - find users with role, emit to each
- [ ] Method: `emitToDepartment(UUID departmentId, NotificationEvent event)` - find users in dept, emit
- [ ] Method: `emitToApprovers(UUID requestId, NotificationEvent event)` - resolve approvers from request
- [ ] Recipient resolution logic:
  - SUBMITTED → all users with approval permission (dept heads, HR, executives)
  - APPROVED/REJECTED/CANCELLED → requestor (employee who submitted)
  - REVOKED → requestor + original approver
- [ ] Use `@Transactional` for DB persistence
- [ ] After DB save, call `sseRegistry.broadcastToUser()` for real-time push