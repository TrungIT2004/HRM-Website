import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import NotificationBell from '@/components/layout/NotificationBell';
import { Notification } from '@/types';
import { renderWithProviders } from '@/test/utils';
import { apiClient } from '@/services/apiClient';

// Mock apiClient
jest.mock('@/services/apiClient', () => ({
  apiClient: {
    notifications: {
      getAll: jest.fn(),
      getUnreadCount: jest.fn(),
      markAsRead: jest.fn(),
      markAllAsRead: jest.fn(),
      streamUrl: jest.fn().mockReturnValue('/api/notifications/stream'),
    },
  },
}));

const mockNotifications: Notification[] = [
  {
    notificationId: '1',
    recipientId: 'user-1',
    senderId: 'user-2',
    requestType: 'LEAVE',
    requestId: 'leave-1',
    action: 'APPROVED',
    title: 'Leave Request Approved',
    message: 'Your leave has been approved by John Doe',
    priority: 'NORMAL',
    metadata: { approverName: 'John Doe' },
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
    message: 'Your overtime request has been rejected',
    priority: 'HIGH',
    metadata: { approverName: 'Jane Smith' },
    isRead: true,
    isSeen: true,
    count: 1,
    createdAt: '2026-09-02T10:00:00Z',
    updatedAt: '2026-09-02T10:00:00Z',
  },
  {
    notificationId: '3',
    recipientId: 'user-1',
    senderId: 'user-4',
    requestType: 'RESIGNATION',
    requestId: 'resignation-1',
    action: 'SUBMITTED',
    title: 'New Resignation Request',
    message: 'Employee submitted resignation request',
    priority: 'URGENT',
    metadata: {},
    isRead: false,
    isSeen: false,
    count: 1,
    createdAt: '2026-09-03T10:00:00Z',
    updatedAt: '2026-09-03T10:00:00Z',
  },
];

// Helper to wait for async operations to settle
async function flushPromises() {
  await act(async () => {
    await Promise.resolve();
    // Flush any pending microtasks
    await Promise.resolve();
  });
}

describe('NotificationBell', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    localStorage.setItem('act_hrm_access_token', 'test-token');
    localStorage.setItem('act_hrm_unread_count', '0');

    // Setup default mock responses
    (apiClient.notifications.getAll as jest.Mock).mockResolvedValue({
      content: mockNotifications,
      totalElements: 3,
      totalPages: 1,
      size: 20,
      number: 0,
      last: true,
    });
    (apiClient.notifications.getUnreadCount as jest.Mock).mockResolvedValue({ count: 2 });
    (apiClient.notifications.markAsRead as jest.Mock).mockResolvedValue(undefined);
    (apiClient.notifications.markAllAsRead as jest.Mock).mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.useRealTimers();
    localStorage.clear();
  });

  describe('Badge Count', () => {
    it('renders badge with unread count', () => {
      renderWithProviders(<NotificationBell unreadCount={3} />);

      const badge = screen.getByText('3');
      expect(badge).toBeInTheDocument();
    });

    it('shows 99+ when count exceeds 99', () => {
      renderWithProviders(<NotificationBell unreadCount={150} />);

      const badge = screen.getByText('99+');
      expect(badge).toBeInTheDocument();
    });

    it('does not render badge when count is 0', () => {
      renderWithProviders(<NotificationBell unreadCount={0} />);

      expect(screen.queryByText('0')).not.toBeInTheDocument();
    });

    it('shows correct aria-label with unread count', () => {
      renderWithProviders(<NotificationBell unreadCount={5} />);

      const button = screen.getByRole('button', { name: /notifications, 5 unread/i });
      expect(button).toBeInTheDocument();
    });
  });

  describe('Dropdown Render', () => {
    it('opens dropdown when bell is clicked', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      await waitFor(() => {
        expect(screen.getByText('Thông báo')).toBeInTheDocument();
      });
    });

    it('shows loading state while fetching notifications', async () => {
      let resolvePromise: (value: any) => void;
      const promise = new Promise(resolve => { resolvePromise = resolve; });
      (apiClient.notifications.getAll as jest.Mock).mockReturnValue(promise);

      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Look for loading spinner by its animate-spin class
      await waitFor(() => {
        expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
      });

      act(() => {
        resolvePromise!({
          content: mockNotifications,
          totalElements: 3,
          totalPages: 1,
          size: 20,
          number: 0,
          last: true,
        });
      });

      await waitFor(() => {
        expect(screen.getByText('Leave Request Approved')).toBeInTheDocument();
      });
    });

    it('renders notification list with correct data', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByText('Leave Request Approved')).toBeInTheDocument();
        expect(screen.getByText('Your leave has been approved by John Doe')).toBeInTheDocument();
        expect(screen.getByText('Overtime Request Rejected')).toBeInTheDocument();
        expect(screen.getByText('New Resignation Request')).toBeInTheDocument();
      });
    });

    it('shows different icons for different actions', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        // Approved - Check icon (from lucide-react)
        expect(screen.getByText('Leave Request Approved').closest('button')?.querySelector('svg')).toBeInTheDocument();
        // Rejected - X icon
        expect(screen.getByText('Overtime Request Rejected').closest('button')?.querySelector('svg')).toBeInTheDocument();
        // Submitted - Bell icon
        expect(screen.getByText('New Resignation Request').closest('button')?.querySelector('svg')).toBeInTheDocument();
      });
    });

    it('highlights unread notifications with blue background', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        const unreadItems = screen.getAllByText('Leave Request Approved');
        expect(unreadItems[0].closest('button')).toHaveClass('bg-blue-50');
      });
    });

    it('shows blue dot indicator for unread notifications', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        // Find blue dot indicators (w-1.5 h-1.5 rounded-full bg-blue-500)
        const blueDots = screen.getAllByText('Leave Request Approved');
        const button1 = blueDots[0].closest('button');
        const dot1 = button1?.querySelector('.bg-blue-500');
        expect(dot1).toBeInTheDocument();
      });
    });

    it('shows "Mark all read" button when there are unread notifications', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /đánh dấu tất cả đã đọc/i })).toBeInTheDocument();
      });
    });

    it('does not show "Mark all read" when all are read', async () => {
      const allReadNotifications = mockNotifications.map(n => ({ ...n, isRead: true }));
      (apiClient.notifications.getAll as jest.Mock).mockResolvedValue({
        content: allReadNotifications,
        totalElements: 3,
        totalPages: 1,
        size: 20,
        number: 0,
        last: true,
      });

      renderWithProviders(<NotificationBell unreadCount={0} />);

      const bellButton = screen.getByRole('button', { name: /notifications$/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.queryByRole('button', { name: /đánh dấu tất cả đã đọc/i })).not.toBeInTheDocument();
      });
    });

    it('shows "View all notifications" link at bottom', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByRole('link', { name: /xem tất cả thông báo/i })).toBeInTheDocument();
      });
    });
  });

  describe('Mark as Read', () => {
    it('marks notification as read when clicked', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        const notificationButton = screen.getByText('Leave Request Approved').closest('button');
        act(() => {
          userEvent.click(notificationButton!);
        });
      });

      await waitFor(() => {
        expect(apiClient.notifications.markAsRead).toHaveBeenCalledWith('1');
      });
    });

    it('navigates to correct route on notification click', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        const notificationButton = screen.getByText('Leave Request Approved').closest('button');
        act(() => {
          userEvent.click(notificationButton!);
        });
      });

      await waitFor(() => {
        expect(window.location.href).toContain('/leave/leave-1');
      });
    });
  });

  describe('Mark All as Read', () => {
    it('marks all notifications as read when button clicked', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        const markAllButton = screen.getByRole('button', { name: /đánh dấu tất cả đã đọc/i });
        act(() => {
          userEvent.click(markAllButton);
        });
      });

      await waitFor(() => {
        expect(apiClient.notifications.markAllAsRead).toHaveBeenCalled();
      });
    });
  });

  describe('Pagination', () => {
    it.skip('loads more notifications on scroll', async () => {
      // Clear any default mock and set up pagination mocks
      (apiClient.notifications.getAll as jest.Mock).mockReset();
      (apiClient.notifications.getAll as jest.Mock)
        .mockResolvedValueOnce({
          content: mockNotifications.slice(0, 2),
          totalElements: 3,
          totalPages: 2,
          size: 2,
          number: 0,
          last: false,
        })
        .mockResolvedValueOnce({
          content: mockNotifications.slice(2),
          totalElements: 3,
          totalPages: 2,
          size: 2,
          number: 1,
          last: true,
        });

      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByText('Leave Request Approved')).toBeInTheDocument();
      });

      // Scroll to bottom - find the scroll container by className
      const scrollContainer = screen.getByTestId('notification-list').parentElement!;
      act(() => {
        scrollContainer.scrollTop = scrollContainer.scrollHeight;
        scrollContainer.dispatchEvent(new Event('scroll'));
      });

      // Wait for the second fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(apiClient.notifications.getAll).toHaveBeenCalledTimes(2);
        expect(apiClient.notifications.getAll).toHaveBeenLastCalledWith(1, 20, false);
      });
    });

    it('shows "End of notifications" when no more pages', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByText('Đã hết thông báo')).toBeInTheDocument();
      });
    });
  });

  describe('Close Dropdown', () => {
    it('closes dropdown when clicking outside', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      await waitFor(() => {
        expect(screen.getByText('Thông báo')).toBeInTheDocument();
      });

      // Click outside
      act(() => {
        userEvent.click(document.body);
      });

      await waitFor(() => {
        expect(screen.queryByText('Thông báo')).not.toBeInTheDocument();
      });
    });

    it.skip('closes dropdown when notification is clicked', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByText('Thông báo')).toBeInTheDocument();
      });

      const notificationButton = screen.getByText('Leave Request Approved').closest('button');
      act(() => {
        userEvent.click(notificationButton!);
      });

      await waitFor(() => {
        expect(screen.queryByText('Thông báo')).not.toBeInTheDocument();
      });
    });

    it('closes dropdown when "View all" link is clicked', async () => {
      renderWithProviders(<NotificationBell unreadCount={2} />);

      const bellButton = screen.getByRole('button', { name: /notifications, 2 unread/i });
      act(() => {
        userEvent.click(bellButton);
      });

      // Wait for the async fetch to complete
      await flushPromises();

      await waitFor(() => {
        expect(screen.getByText('Thông báo')).toBeInTheDocument();
      });

      const viewAllLink = screen.getByRole('link', { name: /xem tất cả thông báo/i });
      act(() => {
        userEvent.click(viewAllLink);
      });

      await waitFor(() => {
        expect(screen.queryByText('Thông báo')).not.toBeInTheDocument();
      });
    });
  });
});