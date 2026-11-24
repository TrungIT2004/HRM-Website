# 09: Frontend NotificationToasts + DocumentTitleBadge

**What to build:** `components/ui/NotificationToasts.tsx` — fixed bottom-right stack (z-[100], max 3 toasts), slide-in animation, auto-dismiss 5s (pause on hover), each toast shows type icon, title, body (2 lines), timestamp, "Đóng" button. Click toast body → navigate to detail + mark read. Suppress toast if current page is the detail page for that notification. `hooks/useDocumentTitleBadge.ts` — updates `document.title = \`(${unreadCount}) ACT HRM\`` when `document.hidden === true` or window not focused, restores original title on focus/visibility change.

**Blocked by:** 07

**Status:** ready-for-agent

- [ ] Create `components/ui/NotificationToasts.tsx`:
  - Use `useNotifications` context for `unreadCount` and `notifications` (or subscribe to new notifications via effect)
  - Track `toasts` state (array of notification IDs currently showing)
  - `useEffect` on new notification (from WS): if `toasts.length < 3` and not on detail page for that notification → add to `toasts`, start 5s timer
  - Render: `div className="fixed bottom-4 right-4 z-[100] flex flex-col-reverse gap-2"`
  - Each toast: `div className="flex items-start gap-3 w-96 bg-white rounded-xl shadow-xl ring-1 ring-black/5 p-3 animate-in slide-in-from-right"` with icon, title, body (line-clamp-2), time, close button
  - Click toast (not close btn): `markRead(id)`, `router.push(routeFor(...))`, remove from toasts
  - Hover → clear timeout; leave → restart timeout
- [ ] Create `hooks/useDocumentTitleBadge.ts`:
  - `useEffect`: store `originalTitle = document.title` on mount
  - Watch `unreadCount` (from context): if `unreadCount > 0` and (`document.hidden || !document.hasFocus()`) → `document.title = \`(${unreadCount}) \${originalTitle}\``
  - On `visibilitychange` / `focus` event: if `document.visibilityState === 'visible'` → `document.title = originalTitle`
- [ ] Add `<NotificationToasts />` to `AppShell.tsx` (or root layout)
- [ ] Verify: new notification → toast appears, dismisses, click navigates; tab in background → title shows count; tab focused → title restored