# HRM Website — Real-time Notification System Specification

## Problem Statement

Employees and managers currently have no real-time way to know when their requests (leave, overtime, resignation, asset borrow, etc.) are approved or rejected. They must manually refresh pages or check email. Managers also don't get notified when team members submit new requests requiring their approval.

## Solution

Build a generic, reusable real-time notification system using **Server-Sent Events (SSE)** that:
1. **Persists** all notifications in the existing `notifications` PostgreSQL table (extended with new columns)
2. **Pushes** real-time updates to any open browser tab via SSE
3. **Shows** a Facebook-style bottom-right toast popup when a request status changes
4. **Displays** a notification bell icon in the top navbar with unread count badge and dropdown history
5. **Updates** the browser tab favicon/title with unread count when tab is in background
6. **Works generically** for all approvable request types: Leave, Overtime, Resignation, Asset Request, and future types

---

## User Stories

### Employee Notifications (Requestor)
1. As an employee, I want to receive a real-time popup when my leave request is **approved**, so that I know immediately without refreshing.
2. As an employee, I want to receive a real-time popup when my leave request is **rejected**, so that I see the rejection reason instantly.
3. As an employee, I want to receive a real-time popup when my overtime request is **approved/rejected**, so that I can plan my schedule.
4. As an employee, I want to receive a real-time popup when my resignation request status changes, so that I'm informed of next steps.
5. As an employee, I want to receive a real-time popup when my asset borrow request is **approved/rejected**, so that I know when to pick up equipment.
6. As an employee, I want to see a red badge on the notification bell showing my **unread count**, so that I know there are new notifications at a glance.
7. As an employee, I want to click the bell and see a **dropdown list** of all my notifications (read and unread), so that I can review history.
8. As an employee, I want notifications to **persist across page reloads**, so that I don't miss anything if I close the tab.
9. As an employee with the tab in background, I want the **browser tab title/favicon to show unread count**, so that I notice new notifications even when not actively viewing the HRM site.

### Manager/Approver Notifications
10. As a manager, I want to receive a real-time popup when a team member **submits a new leave request**, so that I can approve it promptly.
11. As a manager, I want to receive a real-time popup when a team member **submits a new overtime request**, so that I can review it.
12. As a manager, I want to receive a real-time popup when a team member **submits a resignation request**, so that I can initiate offboarding.
13. As a manager, I want to receive a real-time popup when a team member **requests to borrow an asset**, so that I can approve allocation.
14. As a manager, I want to see an **unread badge on the notification bell** for pending approvals, so that I know how many items need my attention.
15. As an HR admin, I want to receive notifications for **all company-wide requests** (when I have permission), so that I stay informed.

### System/Technical
16. As a developer, I want a **single generic `NotificationService`** that all request services (Leave, Overtime, Resignation, Asset) call, so that adding new request types requires zero notification code changes.
17. As a developer, I want the **SSE connection to auto-reconnect** on network interruption, so that users don't miss notifications.
18. As a developer, I want **REST fallback endpoints** (list, mark-read, unread-count) for initial load and non-SSE clients, so that the system works even if SSE fails.
19. As a QA engineer, I want **unit tests for the NotificationService** verifying correct recipient resolution per request type, so that notifications go to the right people.

---

## Implementation Decisions

### 1. Database Schema — Extend Existing `notifications` Table

The existing `notifications` table (from `01_hrm.sql`) has:
- `notification_id` (PK, UUID)
- `recipent_id` (UUID, recipient user)
- `sender_id` (UUID, actor who triggered)
- `type` (VARCHAR, CHECK: POST_REACTION, COMMENT, REPLY, etc.)
- `entity_type` (VARCHAR, CHECK: POST, COMMENT, USER)
- `entity_id` (UUID)
- `is_read`, `is_seen` (BOOLEAN)
- `count` (INTEGER)
- `created_at`, `updated_at` (TIMESTAMP)

**New columns to add via migration:**
- `request_type` (VARCHAR(50)) — `LEAVE`, `OVERTIME`, `RESIGNATION`, `ASSET_REQUEST`, `GENERIC`
- `request_id` (UUID) — FK to the request entity (leave_requests.request_id, overtime_records.overtime_record_id, etc.)
- `action` (VARCHAR(30)) — `SUBMITTED`, `APPROVED`, `REJECTED`, `CANCELLED`, `REVOKED`
- `title` (VARCHAR(255)) — Short display title, e.g., "Leave Request Approved"
- `message` (TEXT) — Full message, e.g., "Your leave from 2026-09-01 to 2026-09-05 has been approved by John Doe"
- `priority` (VARCHAR(20)) — `NORMAL`, `HIGH`, `URGENT` (for future escalation)
- `metadata` (JSONB) — Flexible extra data: `{ "approverName": "John Doe", "fromDate": "2026-09-01", ... }`

**New CHECK constraints:**
- `request_type` IN (`LEAVE`, `OVERTIME`, `RESIGNATION`, `ASSET_REQUEST`, `GENERIC`)
- `action` IN (`SUBMITTED`, `APPROVED`, `REJECTED`, `CANCELLED`, `REVOKED`)
- `priority` IN (`NORMAL`, `HIGH`, `URGENT`)

**Indexes to add:**
- `idx_notifications_recipient_unread` ON `notifications(recipent_id, is_read)` WHERE `is_read = false`
- `idx_notifications_request` ON `notifications(request_type, request_id)`

### 2. Backend — NotificationService (Central Emitter)

**Interface:**
```java
public interface NotificationService {
    void emit(UUID recipientId, NotificationEvent event);
    void emitToRole(String role, NotificationEvent event); // e.g., all MANAGERS in dept
    void emitToDepartment(UUID departmentId, NotificationEvent event);
}

public record NotificationEvent(
    NotificationType type,        // LEAVE, OVERTIME, RESIGNATION, ASSET_REQUEST
    UUID requestId,
    Action action,                // SUBMITTED, APPROVED, REJECTED, CANCELLED
    String title,
    String message,
    Map<String, Object> metadata,
    Priority priority
) {}
```

**Called from service layer (single line per status change):**
- `LeaveService.handleLeaveRequest()` → `notificationService.emit(requestorId, event)` on APPROVED/REJECTED
- `LeaveService.createLeaveRequest()` → `notificationService.emitToApprovers(approverIds, event)` on SUBMITTED
- `OvertimeService.handleOvertimeRequest()` → same pattern
- `ResignationService.finalizeResignationRequest()` / `createResignationRequest()` → same
- `AssetRequestService.handleAssetRequest()` / `createAssetRequest()` → same

**Recipient resolution logic:**
- `SUBMITTED` → All users with approval permission for that request (department heads, HR, executives per existing auth logic)
- `APPROVED`/`REJECTED`/`CANCELLED` → The requestor (employee who submitted)
- `REVOKED` → Requestor + original approver

### 3. Backend — SSE Endpoint

**Route:** `GET /api/notifications/stream`
- Response: `text/event-stream`
- Auth: JWT via `Authorization` header or cookie (reuse existing `apiClient` token logic)
- Events:
  - `notification` — New notification payload (full object)
  - `unread_count` — `{ count: number }` for badge updates
  - `heartbeat` — Every 30s to keep connection alive
- Auto-reconnect: Client handles via `EventSource` native reconnection
- Connection lifecycle: Open on login, close on logout/tab close

**Route:** `GET /api/notifications` — Paginated list (for dropdown history)
- Query: `page`, `size`, `unreadOnly` (boolean)
- Response: `PageResponse<NotificationDTO>`

**Route:** `GET /api/notifications/unread-count` — Badge count
- Response: `{ count: number }`

**Route:** `PATCH /api/notifications/{id}/read` — Mark single as read
**Route:** `PATCH /api/notifications/read-all` — Mark all as read

### 4. Frontend — NotificationContext (SSE Client)

**State:**
- `notifications: Notification[]` — All fetched + real-time received
- `unreadCount: number` — For bell badge
- `eventSource: EventSource | null` — SSE connection
- `toasts: ToastNotification[]` — Queue for bottom-right popups

**API:**
- `connect()` — Open SSE, fetch initial unread count + recent 20
- `disconnect()` — Close SSE
- `markRead(id)` — Optimistic update + API call
- `markAllRead()` — Batch update
- `pushToast(notification)` — Add to toast queue (auto-dismiss after 5s)

**Integration:**
- Wrap `AppShell` in `NotificationProvider`
- `AuthContext` calls `connect()` on login, `disconnect()` on logout
- Persist `unreadCount` to `localStorage` for tab badge on reload

### 5. Frontend — UI Components

| Component | Location | Description |
|-----------|----------|-------------|
| `NotificationBell` | `components/layout/NotificationBell.tsx` | Bell icon in navbar, shows red badge with `unreadCount`, click → dropdown with list (title, message, time, read status), "Mark all read" link |
| `ToastContainer` | `components/ui/ToastContainer.tsx` | Fixed bottom-right, stacks toasts vertically, each shows `title` + `message`, type-based color (green=approved, red=rejected, blue=submitted), auto-dismiss 5s, click to mark read + navigate to request detail |
| `TabBadge` | `components/ui/TabBadge.tsx` | `useEffect` updates `document.title` and favicon badge (via `<link rel="icon">` swap or canvas) when `unreadCount > 0` |

### 6. Request Type Coverage (Phase 1)

| Request Type | Backend Service | Submit Event | Approve/Reject Event | Frontend Toast Title |
|--------------|-----------------|--------------|---------------------|---------------------|
| Leave | `LeaveService` | SUBMITTED → approvers | APPROVED/REJECTED → requestor | "Leave Request Approved/Rejected" |
| Overtime | `OvertimeService` | SUBMITTED → approvers | APPROVED/REJECTED → requestor | "Overtime Request Approved/Rejected" |
| Resignation | `ResignationService` | SUBMITTED → HR/manager | APPROVED/REJECTED → requestor | "Resignation Request Approved/Rejected" |
| Asset Request | `AssetRequestService` | SUBMITTED → approvers | APPROVED/REJECTED → requestor | "Asset Request Approved/Rejected" |

*Future types (Expense, Training, etc.) follow same pattern — just call `NotificationService.emit()`*

---

## Testing Decisions

| Test | What Makes It Good | Module | Prior Art |
|------|-------------------|--------|-----------|
| NotificationService unit | Verifies correct recipients per action/type; mocks UserRepository | `NotificationServiceTest.java` | `LeaveServiceTest.java` pattern |
| SSE endpoint integration | Connects, receives event, reconnects on disconnect | `NotificationControllerTest.java` | `@SpringBootTest` + `WebTestClient` |
| Frontend context | Mocks EventSource, verifies state updates on message | `NotificationContext.test.tsx` | `AuthContext.test.tsx` pattern |
| NotificationBell | Renders badge count, dropdown opens, marks read | `NotificationBell.test.tsx` | `Navbar.test.tsx` pattern |
| ToastContainer | Stacks toasts, auto-dismisses, click navigates | `ToastContainer.test.tsx` | New — use React Testing Library |
| E2E flow | Create leave request → approve → verify toast + bell update | Playwright test | `CHATBOT_TEST_REPORT.md` pattern |

**Test data:** Use existing test users (`MOCK_USERS` in frontend, seeded DB in backend). No new fixtures needed.

---

## Out of Scope

- Email/push notifications (separate channel, future work)
- Notification preferences (per-user opt-out, frequency digest) — v2
- Real-time "typing..." or presence indicators
- WebSocket fallback (SSE is sufficient for one-way server→client)
- Mobile app / PWA push API integration
- Notification grouping/threading (e.g., "3 leave requests approved")
- Sound/vibration on toast (accessibility: respect `prefers-reduced-motion`)
- Admin notification dashboard (HR view of all notifications)

---

## Further Notes

### Existing Code to Reuse
- **Auth**: `apiClient.ts` already handles JWT, auto-refresh, `credentials: 'include'` — SSE endpoint uses same auth
- **Navbar**: `Navbar.tsx` has user dropdown pattern — `NotificationBell` follows same `animate-in fade-in zoom-in-95` animation
- **Types**: `src/types/index.ts` — add `Notification`, `NotificationEvent`, `ToastNotification` interfaces
- **Mock data**: `src/mock/` — add mock notifications for Storybook/preview
- **Database**: `notifications` table already exists — migration only adds columns/indexes

### Key Files to Create/Modify (Reference)

**Backend:**
- `backend/src/main/java/.../notifications/NotificationService.java` (new)
- `backend/src/main/java/.../notifications/NotificationController.java` (new)
- `backend/src/main/java/.../notifications/entity/Notification.java` (new JPA entity)
- `backend/src/main/java/.../notifications/dto/NotificationDTO.java` (new)
- `backend/src/main/java/.../leave/services/LeaveService.java` (modify — emit on create/handle)
- `backend/src/main/java/.../overtime/services/OvertimeService.java` (modify)
- `backend/src/main/java/.../resignation/services/ResignationService.java` (modify — when exists)
- `backend/src/main/java/.../asset/services/AssetRequestService.java` (modify — when exists)
- `init-db/migration/V2__extend_notifications.sql` (new migration)

**Frontend:**
- `HRM Website/src/context/NotificationContext.tsx` (new)
- `HRM Website/src/components/layout/NotificationBell.tsx` (new)
- `HRM Website/src/components/ui/ToastContainer.tsx` (new)
- `HRM Website/src/components/ui/TabBadge.tsx` (new)
- `HRM Website/src/components/layout/Navbar.tsx` (modify — add NotificationBell)
- `HRM Website/src/components/layout/AppShell.tsx` (modify — wrap with NotificationProvider)
- `HRM Website/src/services/apiClient.ts` (modify — add notification API methods)
- `HRM Website/src/types/index.ts` (modify — add notification types)

### Deployment Notes
- Run DB migration before deploying backend
- SSE requires `proxy_read_timeout` ≥ 60s in nginx (if used) to avoid premature close
- Feature flag: `NEXT_PUBLIC_ENABLE_NOTIFICATIONS=true` for gradual rollout

---

## Acceptance Criteria

1. **Employee submits leave request** → Manager sees toast "New leave request from [Name]" within 2s, bell badge increments
2. **Manager approves leave** → Employee sees toast "Leave Request Approved" within 2s, bell badge increments
3. **Page reload** → Bell badge shows correct unread count from DB, dropdown shows full history
4. **Tab in background** → Browser title shows "(3) ACT HRM", favicon shows red badge with "3"
5. **Network disconnect/reconnect** → SSE auto-reconnects, missed notifications fetched via REST on reconnect
6. **Mark as read** → Badge decrements immediately, notification moves to "read" section in dropdown
7. **All request types** → Leave, Overtime, Resignation, Asset Request all produce correct notifications