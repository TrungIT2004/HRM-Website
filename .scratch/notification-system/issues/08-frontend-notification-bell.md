# 08: Frontend NotificationBell Dropdown

**What to build:** `components/layout/NotificationBell.tsx` — bell icon with unread count badge (red circle, "9+" for >9), click opens Portal dropdown (z-50, anchored bottom-right). Dropdown shows header "Thông báo", max 4 notification items (type icon: Calendar/Clock/UserX/Package/Wrench, title, truncated body, relative time), unread items bold with blue dot. Divider + "Xem tất cả" link → `/notifications`. Click item → navigate to detail route + mark read. Close on outside click/Escape.

**Blocked by:** 07

**Status:** ready-for-agent

- [ ] Create `components/layout/NotificationBell.tsx` as client component (`'use client'`)
- [ ] Use `useNotifications` context from `NotificationProvider`
- [ ] Bell button: `<Bell className="h-5 w-5" />` with badge `unreadCount > 0 ? unreadCount > 9 ? '9+' : unreadCount : null`
- [ ] Dropdown (Portal to body): `div className="fixed right-4 top-16 z-50 w-96 bg-white rounded-2xl shadow-xl ring-1 ring-black/5 animate-in fade-in-100"`
- [ ] Header: "Thông báo" + (unreadCount > 0 ? badge : null)
- [ ] List: map `notifications` (max 4) → item with:
  - Icon: `type === 'LEAVE' ? Calendar : type === 'OVERTIME' ? Clock : type === 'RESIGNATION' ? UserX : type === 'ASSET' ? Package : Wrench`
  - Title (bold if unread), body (1 line clamp), relative time (`formatDistanceToNow` from `date-fns` or custom)
  - Blue dot for unread: `readAt === null && <span className="w-2 h-2 bg-blue-500 rounded-full" />`
  - `onClick`: `markRead(id)`, `router.push(routeFor(referenceType, referenceId))`
- [ ] Footer: `<Link href="/notifications" className="text-sm text-blue-600 hover:underline">Xem tất cả</Link>`
- [ ] Close on outside click (`useRef` + `useEffect` listener) and Escape key
- [ ] Verify: dropdown opens/closes, shows correct data, click navigates + marks read