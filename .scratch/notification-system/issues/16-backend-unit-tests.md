# 16: Backend - Unit Tests for NotificationService & Controller

**What to build:** Unit tests verifying correct recipient resolution per request type/action, and integration tests for SSE endpoint and REST APIs.

**Blocked by:** 15-frontend-navbar-integration

**Status:** ready-for-agent

- [ ] Create `NotificationServiceTest.java`:
  - Test SUBMITTED → resolves approvers (dept heads, HR, executives)
  - Test APPROVED/REJECTED → resolves requestor only
  - Test REVOKED → resolves requestor + original approver
  - Mock UserRepository, verify correct userIds passed to emit
  - Follow `LeaveServiceTest.java` pattern
- [ ] Create `NotificationControllerTest.java`:
  - `@SpringBootTest` + `WebTestClient`
  - Test SSE connection: connect, receive event, reconnect on disconnect
  - Test REST endpoints: list (pagination, unreadOnly), unread-count, mark-read, mark-all-read
  - Test auth: 401 without token, 200 with valid token