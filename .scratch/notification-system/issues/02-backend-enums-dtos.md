# 02: Backend - Notification Enums & DTOs

**What to build:** Create enum types and DTO records for the notification system: NotificationType, NotificationAction, NotificationPriority, NotificationEvent, and NotificationDTO.

**Blocked by:** 01-db-migration

**Status:** ready-for-agent

- [ ] Create `NotificationType.java` enum (LEAVE, OVERTIME, RESIGNATION, ASSET_REQUEST, GENERIC)
- [ ] Create `NotificationAction.java` enum (SUBMITTED, APPROVED, REJECTED, CANCELLED, REVOKED)
- [ ] Create `NotificationPriority.java` enum (NORMAL, HIGH, URGENT)
- [ ] Create `NotificationEvent.java` record (type, requestId, action, title, message, metadata, priority)
- [ ] Create `NotificationDTO.java` response DTO with all fields for frontend