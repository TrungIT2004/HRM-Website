import { http, HttpResponse } from 'msw';

const mockNotifications = [
  {
    notificationId: '1',
    recipientId: 'user-1',
    senderId: 'user-2',
    requestType: 'LEAVE',
    requestId: 'leave-1',
    action: 'APPROVED',
    title: 'Leave Request Approved',
    message: 'Your leave from 2026-09-01 to 2026-09-05 has been approved by John Doe',
    priority: 'NORMAL',
    metadata: { approverName: 'John Doe', fromDate: '2026-09-01', toDate: '2026-09-05' },
    isRead: false,
    isSeen: false,
    count: 1,
    createdAt: '2026-09-01T10:00:00Z',
    updatedAt: '2026-09-01T10:00:00Z',
  },
  {
    notificationId: '2',
    recipientId: 'user-1',
    senderId: 'user-3',
    requestType: 'OVERTIME',
    requestId: 'overtime-1',
    action: 'REJECTED',
    title: 'Overtime Request Rejected',
    message: 'Your overtime request for 2026-09-10 has been rejected',
    priority: 'HIGH',
    metadata: { approverName: 'Jane Smith', date: '2026-09-10' },
    isRead: true,
    isSeen: true,
    count: 1,
    createdAt: '2026-09-02T10:00:00Z',
    updatedAt: '2026-09-02T10:00:00Z',
  },
];

export const handlers = [
  // GET /api/notifications - paginated list
  http.get('/api/notifications', ({ request }) => {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '0', 10);
    const size = parseInt(url.searchParams.get('size') || '20', 10);
    const unreadOnly = url.searchParams.get('unreadOnly') === 'true';

    let filtered = [...mockNotifications];
    if (unreadOnly) {
      filtered = filtered.filter(n => !n.isRead);
    }

    const start = page * size;
    const end = start + size;
    const content = filtered.slice(start, end);

    return HttpResponse.json({
      content,
      totalElements: filtered.length,
      totalPages: Math.ceil(filtered.length / size),
      size,
      number: page,
      last: end >= filtered.length,
    });
  }),

  // GET /api/notifications/unread-count
  http.get('/api/notifications/unread-count', () => {
    const count = mockNotifications.filter(n => !n.isRead).length;
    return HttpResponse.json({ count });
  }),

  // PATCH /api/notifications/:id/read
  http.patch('/api/notifications/:id/read', ({ params }) => {
    const notification = mockNotifications.find(n => n.notificationId === params.id);
    if (notification) {
      notification.isRead = true;
    }
    return HttpResponse.json({ success: true });
  }),

  // PATCH /api/notifications/read-all
  http.patch('/api/notifications/read-all', () => {
    mockNotifications.forEach(n => { n.isRead = true; });
    return HttpResponse.json({ success: true });
  }),

  // SSE endpoint - handled by NotificationContext via EventSource mock
  http.get('/api/notifications/stream', () => {
    return new HttpResponse(null, { status: 200 });
  }),
];