# 20: Future - AssetRequestService Integration

**What to build:** When AssetRequestService is created, integrate NotificationService to emit notifications on asset request creation and status changes.

**Blocked by:** 18-e2e-tests (can be done independently when AssetRequestService exists)

**Status:** ready-for-agent

- [ ] Inject `NotificationService` into `AssetRequestService` (when created)
- [ ] In `createAssetRequest()`: emit `SUBMITTED` to approvers
  - Title: "New Asset Request from [Name]"
  - Message: "[Name] requested to borrow [Asset Name]"
  - Metadata: `{ requestorName, assetName, assetType, fromDate, toDate }`
- [ ] In `handleAssetRequest()` (approve/reject): emit `APPROVED`/`REJECTED` to requestor
  - Title: "Asset Request Approved/Rejected"
  - Message: "Your request to borrow [Asset Name] has been approved/rejected by [Approver]"
  - Metadata: `{ approverName, assetName, fromDate, toDate, rejectionReason? }`
- [ ] Use `NotificationType.ASSET_REQUEST`, appropriate `NotificationAction`