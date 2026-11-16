# 08: Integrate NotificationService with OvertimeService

**What to build:** Modify OvertimeService to emit notifications on overtime request creation, approval/rejection, and cancellation.

**Blocked by:** 06-backend-notification-controller

**Status:** ready-for-agent

- [ ] Inject `NotificationService` into `OvertimeService`
- [ ] In `createOvertimeRequest()`: after save, emit `SUBMITTED` event to approvers
  - Title: "New Overtime Request from [Name]"
  - Message: "[Name] requested overtime on [date] from [time] to [time]"
  - Metadata: `{ requestorName, date, startTime, endTime, isHoliday }`
- [ ] In `handleOvertimeRequest()`: after status change, emit `APPROVED`/`REJECTED` to requestor
  - Title: "Overtime Request Approved/Rejected"
  - Message: "Your overtime on [date] has been approved/rejected by [Approver]"
  - Metadata: `{ approverName, date, rejectionReason? }`
- [ ] In `cancelOvertimeRequest()`: emit `CANCELLED` to approvers
  - Title: "Overtime Request Cancelled"
  - Message: "[Name] cancelled their overtime request on [date]"
- [ ] Use `NotificationType.OVERTIME`, appropriate `NotificationAction`, `Priority.NORMAL`