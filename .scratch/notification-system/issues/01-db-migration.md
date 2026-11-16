# 01: Database Migration - Extend Notifications Table

**What to build:** Extend the existing `notifications` PostgreSQL table with new columns for request-type notifications (request_type, request_id, action, title, message, priority, metadata) plus CHECK constraints and indexes for performance.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Create migration file `init-db/migration/V2__extend_notifications.sql`
- [ ] Add columns: `request_type`, `request_id`, `action`, `title`, `message`, `priority`, `metadata`
- [ ] Add CHECK constraints for `request_type`, `action`, `priority`
- [ ] Add indexes: `idx_notifications_recipient_unread`, `idx_notifications_request`
- [ ] Fix typo: `recipent_id` → `recipient_id` in index (original has typo)