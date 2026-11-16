# 13: Frontend - NotificationBell Component

**What to build:** Create a notification bell icon in the navbar with unread count badge and dropdown history list.

**Blocked by:** 11-frontend-appshell-provider

**Status:** ready-for-agent

- [ ] Create `HRM Website/src/components/layout/NotificationBell.tsx`
- [ ] Bell icon (Lucide `Bell`) in navbar
- [ ] Red badge with `unreadCount` (animate-in like user dropdown)
- [ ] Click → dropdown with list: title, message, relative time, read status
- [ ] Unread items highlighted, read items muted
- [ ] "Mark all read" link at bottom of dropdown
- [ ] Animation: `animate-in fade-in zoom-in-95 duration-150` (matches Navbar user dropdown)
- [ ] Click outside to close dropdown
- [ ] Click notification: mark read + navigate to request detail