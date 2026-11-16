-- V2: Extend notifications table for real-time notification system
-- Adds request-type specific columns, CHECK constraints, and indexes
-- Also fixes the typo: recipent_id -> recipient_id

-- Add new columns for request-type notifications
ALTER TABLE public.notifications
    ADD COLUMN IF NOT EXISTS request_type VARCHAR(50),
    ADD COLUMN IF NOT EXISTS request_id UUID,
    ADD COLUMN IF NOT EXISTS action VARCHAR(30),
    ADD COLUMN IF NOT EXISTS title VARCHAR(255),
    ADD COLUMN IF NOT EXISTS message TEXT,
    ADD COLUMN IF NOT EXISTS priority VARCHAR(20),
    ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Add CHECK constraints for new columns
ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_request_type_check
        CHECK (request_type IS NULL OR request_type IN ('LEAVE', 'OVERTIME', 'RESIGNATION', 'ASSET_REQUEST', 'GENERIC'));

ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_action_check
        CHECK (action IS NULL OR action IN ('SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED', 'REVOKED'));

ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_priority_check
        CHECK (priority IS NULL OR priority IN ('NORMAL', 'HIGH', 'URGENT'));

-- Fix typo: recipent_id -> recipient_id
-- First add the new column with correct spelling
ALTER TABLE public.notifications
    ADD COLUMN IF NOT EXISTS recipient_id UUID;

-- Copy data from old column to new column
UPDATE public.notifications
SET recipient_id = recipent_id
WHERE recipient_id IS NULL;

-- Make recipient_id NOT NULL after data migration
ALTER TABLE public.notifications
    ALTER COLUMN recipient_id SET NOT NULL;

-- Add foreign key constraint for recipient_id (assuming users table exists with user_id)
-- ALTER TABLE public.notifications
--     ADD CONSTRAINT fk_notifications_recipient
--     FOREIGN KEY (recipient_id) REFERENCES public.users(user_id);

-- Add foreign key constraint for sender_id
-- ALTER TABLE public.notifications
--     ADD CONSTRAINT fk_notifications_sender
--     FOREIGN KEY (sender_id) REFERENCES public.users(user_id);

-- Drop the old typo column
ALTER TABLE public.notifications
    DROP COLUMN IF EXISTS recipent_id;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread
    ON public.notifications (recipient_id, is_read)
    WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_notifications_request
    ON public.notifications (request_type, request_id);

-- Optional: Index for querying by recipient and creation time (for pagination)
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created
    ON public.notifications (recipient_id, created_at DESC);

-- Add comments for documentation
COMMENT ON COLUMN public.notifications.request_type IS 'Type of request: LEAVE, OVERTIME, RESIGNATION, ASSET_REQUEST, GENERIC';
COMMENT ON COLUMN public.notifications.request_id IS 'FK to the request entity (leave_requests.request_id, overtime_records.overtime_record_id, etc.)';
COMMENT ON COLUMN public.notifications.action IS 'Action that triggered notification: SUBMITTED, APPROVED, REJECTED, CANCELLED, REVOKED';
COMMENT ON COLUMN public.notifications.title IS 'Short display title, e.g., Leave Request Approved';
COMMENT ON COLUMN public.notifications.message IS 'Full message with details';
COMMENT ON COLUMN public.notifications.priority IS 'Priority level: NORMAL, HIGH, URGENT';
COMMENT ON COLUMN public.notifications.metadata IS 'Flexible extra data as JSONB: { "approverName": "John Doe", "fromDate": "2026-09-01", ... }';
COMMENT ON COLUMN public.notifications.recipient_id IS 'Recipient user ID (fixed typo from recipent_id)';