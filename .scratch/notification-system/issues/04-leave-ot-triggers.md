# 04: Backend Leave/OT Notification Triggers

**What to build:** `LeaveService` and `OvertimeService` publish `NotificationEvent` via `ApplicationEventPublisher` after successful `repo.save()`. Events: Leave created → approver (HIGH); Leave approved/rejected → requestor (NORMAL); OT created → approver (HIGH); OT approved/rejected → requestor (NORMAL). Integration test with `WebSocketStompClient` verifies realtime delivery.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Inject `ApplicationEventPublisher` into `LeaveService` and `OvertimeService`
- [ ] In `LeaveService.createLeaveRequest()`: after save, publish `NotificationEvent` to assigned approver (determine via existing approval logic: manager/HR). Type=LEAVE, priority=HIGH, metadata={requestorName, department, fromDate, toDate, totalDays}
- [ ] In `LeaveService.handleLeaveRequest()` (approve/reject): after save, publish to requestor. Type=LEAVE, priority=NORMAL, metadata={status, approverName, rejectionReason?}
- [ ] In `OvertimeService.createOvertimeRequest()`: after save, publish to assigned approver. Type=OVERTIME, priority=HIGH, metadata={requestorName, department, date, hours, type}
- [ ] In `OvertimeService.approve/reject()`: after save, publish to requestor. Type=OVERTIME, priority=NORMAL, metadata={status, approverName, rejectionReason?}
- [ ] Write integration test (`@SpringBootTest` + `WebSocketStompClient`): connect as user A (approver), call `LeaveService.createLeaveRequest()` as user B, assert `NOTIFICATION_CREATED` received by user A with correct payload
- [ ] Verify: integration test passes; manual test: create leave request → notification appears in approver's dropdown