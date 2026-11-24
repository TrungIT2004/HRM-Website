# 10: Frontend Notifications Page

**What to build:** `app/notifications/page.tsx` — server component fetches first page (page=0, size=10) via `notificationService.getNotifications()`. Client wrapper (`NotificationsPageClient.tsx`) handles pagination (infinite scroll or numbered), tabs (All/Unread/Read), filter chips (Leave/OT/Resignation/Asset/IT), table (Type icon | Title | Requestor | Time | Status badge), "Mark all as read" button, empty state. Row click → navigate to detail route + mark read.

**Blocked by:** 06, 07

**Status:** ready-for-agent

- [ ] Create `app/notifications/page.tsx` (server component):
  - `const initialData = await notificationService.getNotifications({ page: 0, size: 10 })`
  - Pass `initialData` to client component
- [ ] Create `components/notifications/NotificationsPageClient.tsx` (`'use client'`):
  - State: `page`, `filters: { type?, readStatus? }`, `data`, `loading`
  - Tabs: `['ALL', 'UNREAD', 'READ']` → sets `readStatus` filter
  - Filter chips: 5 types → sets `type` filter
  - Table: columns [Type, Title, Requestor, Time, Status]
    - Type: icon + label (color-coded)
    - Title: truncate 2 lines
    - Requestor: from `metadata.requestorName`
    - Time: relative format
    - Status: badge (Unread=blue, Read=gray)
  - Row `onClick`: `markRead(id)`, `router.push(routeFor(referenceType, referenceId))`
  - Pagination: "Load more" button (infinite scroll) or numbered pages
  - "Mark all as read" button (top-right): calls `markAllRead()`, refreshes list
  - Empty state: "Không có thông báo nào" with bell icon
- [ ] Add route mapping helper `routeFor(referenceType, referenceId)`:
  - LEAVE_REQUEST → `/leave/requests/{id}`
  - OVERTIME_RECORD → `/overtime/requests/{id}`
  - RESIGNATION_REQUEST → `/resignations/{id}`
  - ASSET_REQUEST → `/assets/requests/{id}`
  - IT_TICKET → `/it/tickets/{id}`
- [ ] Verify: page loads, filters work, pagination works, mark-all-read works, navigation works