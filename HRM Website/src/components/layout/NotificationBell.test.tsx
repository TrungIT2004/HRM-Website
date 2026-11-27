import React from 'react';
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { NotificationBell } from './NotificationBell';

// Mock the NotificationProvider
vi.mock('@/components/providers/NotificationProvider', () => ({
  useNotifications: () => ({
    notifications: [
      {
        notificationId: 'notif-1',
        type: 'LEAVE' as const,
        title: 'Leave Approved',
        body: 'Your leave request has been approved',
        referenceId: 'leave-123',
        referenceType: 'LEAVE_REQUEST' as const,
        priority: 'NORMAL' as const,
        metadata: {},
        readAt: null,
        createdAt: new Date().toISOString(),
      },
      {
        notificationId: 'notif-2',
        type: 'OVERTIME' as const,
        title: 'Overtime Request',
        body: 'New overtime request submitted',
        referenceId: 'ot-456',
        referenceType: 'OVERTIME_RECORD' as const,
        priority: 'HIGH' as const,
        metadata: {},
        readAt: new Date().toISOString(),
        createdAt: new Date(Date.now() - 3600000).toISOString(),
      },
    ],
    unreadCount: 1,
    markRead: vi.fn().mockResolvedValue(undefined),
    markAllRead: vi.fn().mockResolvedValue(undefined),
    isConnected: true,
    fetchPage: vi.fn().mockResolvedValue({ content: [], totalElements: 0, totalPages: 0, size: 0, number: 0 }),
    fetchUnreadCount: vi.fn().mockResolvedValue(undefined),
    loadInitialNotifications: vi.fn().mockResolvedValue(undefined),
  }),
}));

// Mock next/navigation
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
  }),
}));

// Mock next/link
vi.mock('next/link', () => ({
  default: ({ children, href, onClick }: { children: React.ReactNode; href: string; onClick?: () => void }) => (
    <a href={href} onClick={onClick}>{children}</a>
  ),
}));

describe('NotificationBell', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('renders bell icon', () => {
    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    expect(bellButton).toBeInTheDocument();
    expect(bellButton).toContainHTML('<svg');
  });

  it('shows unread count badge when count > 0', () => {
    render(<NotificationBell />);

    // Should show "1" badge
    expect(screen.getByText('1')).toBeInTheDocument();
  });

  it('opens dropdown on click', async () => {
    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    fireEvent.click(bellButton);

    await waitFor(() => {
      expect(screen.getByText('Thông báo')).toBeInTheDocument();
    });

    expect(screen.getByText('1 chưa đọc')).toBeInTheDocument();
    expect(screen.getByText('Leave Approved')).toBeInTheDocument();
    expect(screen.getByText('Overtime Request')).toBeInTheDocument();
  });

  it('closes dropdown on outside click', async () => {
    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    fireEvent.click(bellButton);

    await waitFor(() => {
      expect(screen.getByText('Thông báo')).toBeInTheDocument();
    });

    // Click outside
    fireEvent.mouseDown(document.body);

    // Dropdown should close - the header should not be visible
    expect(screen.queryByText('Thông báo')).not.toBeInTheDocument();
  });

  it('closes dropdown on Escape key', async () => {
    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    fireEvent.click(bellButton);

    await waitFor(() => {
      expect(screen.getByText('Thông báo')).toBeInTheDocument();
    });

    fireEvent.keyDown(document, { key: 'Escape' });

    expect(screen.queryByText('Thông báo')).not.toBeInTheDocument();
  });

  it('marks notification as read on click', async () => {
    const { useNotifications } = await import('@/components/providers/NotificationProvider');
    const mockMarkRead = vi.fn().mockResolvedValue(undefined);
    vi.mocked(useNotifications).mockReturnValue({
      notifications: [
        {
          notificationId: 'notif-1',
          type: 'LEAVE' as const,
          title: 'Leave Approved',
          body: 'Your leave request has been approved',
          referenceId: 'leave-123',
          referenceType: 'LEAVE_REQUEST' as const,
          priority: 'NORMAL' as const,
          metadata: {},
          readAt: null,
          createdAt: new Date().toISOString(),
        },
      ],
      unreadCount: 1,
      markRead: mockMarkRead,
      markAllRead: vi.fn().mockResolvedValue(undefined),
      isConnected: true,
      fetchPage: vi.fn().mockResolvedValue({ content: [], totalElements: 0, totalPages: 0, size: 0, number: 0 }),
      fetchUnreadCount: vi.fn().mockResolvedValue(undefined),
      loadInitialNotifications: vi.fn().mockResolvedValue(undefined),
    });

    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    fireEvent.click(bellButton);

    await waitFor(() => {
      expect(screen.getByText('Leave Approved')).toBeInTheDocument();
    });

    // Click on the notification
    fireEvent.click(screen.getByText('Leave Approved').closest('button')!);

    await waitFor(() => {
      expect(mockMarkRead).toHaveBeenCalledWith('notif-1');
    });
  });

  it('shows "Xem tất cả" link at bottom', async () => {
    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    fireEvent.click(bellButton);

    await waitFor(() => {
      expect(screen.getByText('Xem tất cả')).toBeInTheDocument();
    });
  });

  it('shows correct icons for different notification types', async () => {
    const { useNotifications } = await import('@/components/providers/NotificationProvider');
    vi.mocked(useNotifications).mockReturnValue({
      notifications: [
        {
          notificationId: 'notif-1',
          type: 'LEAVE' as const,
          title: 'Leave',
          body: 'Leave body',
          referenceId: '1',
          referenceType: 'LEAVE_REQUEST' as const,
          priority: 'NORMAL' as const,
          metadata: {},
          readAt: null,
          createdAt: new Date().toISOString(),
        },
        {
          notificationId: 'notif-2',
          type: 'OVERTIME' as const,
          title: 'Overtime',
          body: 'Overtime body',
          referenceId: '2',
          referenceType: 'OVERTIME_RECORD' as const,
          priority: 'NORMAL' as const,
          metadata: {},
          readAt: null,
          createdAt: new Date().toISOString(),
        },
        {
          notificationId: 'notif-3',
          type: 'IT_TICKET' as const,
          title: 'IT Ticket',
          body: 'IT Ticket body',
          referenceId: '3',
          referenceType: 'IT_TICKET' as const,
          priority: 'NORMAL' as const,
          metadata: {},
          readAt: null,
          createdAt: new Date().toISOString(),
        },
      ],
      unreadCount: 3,
      markRead: vi.fn().mockResolvedValue(undefined),
      markAllRead: vi.fn().mockResolvedValue(undefined),
      isConnected: true,
      fetchPage: vi.fn().mockResolvedValue({ content: [], totalElements: 0, totalPages: 0, size: 0, number: 0 }),
      fetchUnreadCount: vi.fn().mockResolvedValue(undefined),
      loadInitialNotifications: vi.fn().mockResolvedValue(undefined),
    });

    render(<NotificationBell />);

    const bellButton = screen.getByLabelText(/Thông báo/);
    fireEvent.click(bellButton);

    await waitFor(() => {
      expect(screen.getByText('Leave')).toBeInTheDocument();
    });

    // Each notification should have an icon (svg)
    const svgs = screen.getAllByRole('img');
    expect(svgs.length).toBeGreaterThanOrEqual(3);
  });
});