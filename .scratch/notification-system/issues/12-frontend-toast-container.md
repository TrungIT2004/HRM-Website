# 12: Frontend - ToastContainer Component

**What to build:** Create a bottom-right toast container that stacks notifications vertically, shows title+message with action-based colors, auto-dismisses after 5s, and supports click-to-navigate.

**Blocked by:** 11-frontend-appshell-provider

**Status:** ready-for-agent

- [ ] Create `HRM Website/src/components/ui/ToastContainer.tsx`
- [ ] Fixed position bottom-right, z-index 9999, vertical stack (newest on top)
- [ ] Each toast shows: `title` + `message`
- [ ] Color coding: green (APPROVED), red (REJECTED), blue (SUBMITTED), amber (CANCELLED)
- [ ] Auto-dismiss after 5 seconds with slide-out animation
- [ ] Click toast: mark read + navigate to request detail page
- [ ] Follow existing UI patterns (Tailwind, Lucide icons)
- [ ] Respect `prefers-reduced-motion` for accessibility
- [ ] Add to `AppShell.tsx` as sibling to main content