# 07: Integrate NotificationService with LeaveService

**What to build:** Modify LeaveService to emit notifications on leave request creation, approval/rejection, and cancellation.

**Blocked by:** 06-backend-notification-controller

**Status:** ready-for-agent

- [ ] Inject `NotificationService` into `LeaveService`
- [ ] In `createLeaveRequest()`: after save, emit `SUBMITTED` event to approvers
  - Title: "New Leave Request from [Name]"
  - Message: "[Name] requested leave from [date] to [date]"
  - Metadata: `{ requestorName, fromDate, toDate, department }`
- [ ] In `handleLeaveRequest()`: after status change, emit `APPROVED`/`REJECTED` to requestor
  - Title: "Leave Request Approved/Rejected"
  - Message: "Your leave from [date] to [date] has been approved/rejected by [Approver]"
  - Metadata: `{ approverName, fromDate, toDate, rejectionReason? }`
- [ ] In `cancelLeaveRequest()`: emit `CANCELLED` to approvers
  - Title: "Leave Request Cancelled"
  - Message: "[Name] cancelled their leave request from [date] to [date]"
- [ ] Use `NotificationType.LEAVE`, appropriate `NotificationAction`, `Priority.NORMAL`