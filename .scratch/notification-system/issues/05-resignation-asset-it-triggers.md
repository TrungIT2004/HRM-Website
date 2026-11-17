# 05: Backend Resignation/Asset/IT Notification Triggers

**What to build:** `ResignationService`, `AssetService`, `ItTicketService` publish `NotificationEvent` on key transitions. Resignation submitted → manager + HR/executive (HIGH); Resignation approved/rejected → requestor (NORMAL); Asset request created → asset approver (HIGH); Asset approved/rejected → requestor (NORMAL); IT ticket created/claimed → assignee (HIGH); IT ticket resolved → reporter (NORMAL).

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Inject `ApplicationEventPublisher` into `ResignationService`, `AssetService`, `ItTicketService`
- [ ] `ResignationService.submit()`: after save, publish to manager (from `ResignationRequest.manager`) AND HR/executive (query users with RESIGN_APPROVE permission or Executive Leadership dept). Type=RESIGNATION, priority=HIGH, metadata={employeeName, department, lastWorkingDate, reason}
- [ ] `ResignationService.approve/reject()`: after save, publish to requestor. Type=RESIGNATION, priority=NORMAL, metadata={status, approverName, comment?}
- [ ] `AssetService.createRequest()`: after save, publish to asset approver (query users with ASSET_APPROVE permission or IT dept head). Type=ASSET, priority=HIGH, metadata={requestorName, category, reason, neededByDate}
- [ ] `AssetService.approve/reject()` (need to add these methods if not exist): after save, publish to requestor. Type=ASSET, priority=NORMAL, metadata={status, approverName, rejectionReason?}
- [ ] `ItTicketService.create()`: after save, publish to IT handlers (users with IT_TICKET_HANDLE permission). Type=IT_TICKET, priority=HIGH, metadata={reporterName, category, deviceInfo, description}
- [ ] `ItTicketService.claim()`: after save, publish to assignee (claimer). Type=IT_TICKET, priority=HIGH, metadata={ticketId, reporterName}
- [ ] `ItTicketService.resolve()`: after save, publish to reporter. Type=IT_TICKET, priority=NORMAL, metadata={status, resolveNote, resolvedBy}
- [ ] Write integration tests for each (or extend #04 test)
- [ ] Verify: manual test each flow → notification delivered to correct recipient