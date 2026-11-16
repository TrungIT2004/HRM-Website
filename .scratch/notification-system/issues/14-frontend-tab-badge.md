# 14: Frontend - TabBadge Component (Favicon/Title Unread Count)

**What to build:** Create a component that updates browser tab title and favicon with unread count when tab is in background.

**Blocked by:** 11-frontend-appshell-provider

**Status:** ready-for-agent

- [ ] Create `HRM Website/src/components/ui/TabBadge.tsx`
- [ ] `useEffect` watching `unreadCount` from NotificationContext
- [ ] When `unreadCount > 0`: update `document.title` to `"(${count}) ACT HRM"`
- [ ] When `unreadCount > 0`: update favicon with red badge overlay
  - Create canvas, draw existing favicon, overlay red circle with white count text
  - Update `<link rel="icon">` href with data URL
- [ ] When `unreadCount === 0`: restore original title and favicon
- [ ] Add to `AppShell.tsx` (renders nothing, just side effects)