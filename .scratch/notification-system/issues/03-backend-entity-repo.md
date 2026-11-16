# 03: Backend - Notification JPA Entity & Repository

**What to build:** Create the JPA entity mapping for the extended notifications table and a Spring Data JPA repository with custom queries for unread count, paginated list, and recipient-based lookups.

**Blocked by:** 02-backend-enums-dtos

**Status:** ready-for-agent

- [ ] Create `Notification.java` entity mapping all columns (including new ones)
- [ ] Fix column name mapping: `recipient_id` (database has typo `recipent_id`)
- [ ] Create `NotificationRepository.java` extending `JpaRepository<Notification, UUID>`
- [ ] Add custom query: `findByRecipientIdAndIsReadFalse()`
- [ ] Add custom query: `findByRecipientIdOrderByCreatedAtDesc(Pageable)`
- [ ] Add custom query: `countByRecipientIdAndIsReadFalse()`
- [ ] Add query: `findByRequestTypeAndRequestId()`