# 19: Future - ResignationService Integration

**What to build:** When ResignationService is created, integrate NotificationService to emit notifications on resignation request creation and status changes.

**Blocked by:** 18-e2e-tests (can be done independently when ResignationService exists)

**Status:** ready-for-agent

- [ ] Inject `NotificationService` into `ResignationService` (when created)
- [ ] In `createResignationRequest()`: emit `SUBMITTED` to HR/manager
  - Title: "New Resignation Request from [Name]"
  - Message: "[Name] submitted a resignation request effective [date]"
  - Metadata: `{ requestorName, effectiveDate, department }`
- [ ] In `finalizeResignationRequest()` (approve/reject): emit `APPROVED`/`REJECTED` to requestor
  - Title: "Resignation Request Approved/Rejected"
  - Message: "Your resignation request has been approved/rejected by [Approver]"
  - Metadata: `{ approverName, effectiveDate, rejectionReason? }`
- [ ] Use `NotificationType.RESIGNATION`, appropriate `NotificationAction`