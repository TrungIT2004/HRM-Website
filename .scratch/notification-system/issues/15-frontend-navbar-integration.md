# 15: Frontend - Integrate NotificationBell into Navbar

**What to build:** Add the NotificationBell component to the Navbar, positioned between the camera status badge and user avatar.

**Blocked by:** 13-frontend-notification-bell, 14-frontend-tab-badge

**Status:** ready-for-agent

- [ ] Modify `HRM Website/src/components/layout/Navbar.tsx`:
  - Import `NotificationBell`
  - Add `<NotificationBell />` in the right section
  - Position: between camera sync status badge and user dropdown
  - Ensure proper spacing with existing gap classes
- [ ] Verify badge renders correctly with existing navbar styling