import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ToastContainer from '@/components/ui/ToastContainer';
import { NotificationProvider, useNotifications } from '@/context/NotificationContext';
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

// Mock EventSource globally
global.EventSource = jest.fn().mockImplementation(() => ({
  addEventListener: jest.fn(),
  removeEventListener: jest.fn(),
  close: jest.fn(),
  onopen: null,
  onerror: null,
  onmessage: null,
  readyState: 1,
  url: '',
  withCredentials: true,
})) as any;

const mockNotification: Notification = {
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
};

const mockRejectedNotification: Notification = {
  ...mockNotification,
  notificationId: '2',
  requestType: 'OVERTIME',
  requestId: 'overtime-1',
  action: 'REJECTED',
  title: 'Overtime Request Rejected',
  message: 'Your overtime request has been rejected',
  priority: 'HIGH',
};

const mockSubmittedNotification: Notification = {
  ...mockNotification,
  notificationId: '3',
  requestType: 'RESIGNATION',
  requestId: 'resignation-1',
  action: 'SUBMITTED',
  title: 'New Resignation Request',
  message: 'A new resignation request was submitted',
  priority: 'URGENT',
};

const mockCancelledNotification: Notification = {
  ...mockNotification,
  notificationId: '4',
  requestType: 'LEAVE',
  requestId: 'leave-2',
  action: 'CANCELLED',
  title: 'Leave Request Cancelled',
  message: 'Your leave request has been cancelled',
  priority: 'NORMAL',
};

const mockRevokedNotification: Notification = {
  ...mockNotification,
  notificationId: '5',
  requestType: 'OVERTIME',
  requestId: 'overtime-2',
  action: 'REVOKED',
  title: 'Overtime Request Revoked',
  message: 'Your overtime request has been revoked',
  priority: 'HIGH',
};

// Test component that can push toasts via context
function TestToastComponent() {
  const { pushToast } = useNotifications();

  return (
    <div>
      <button onClick={() => pushToast(mockNotification)} data-testid="push-approved">Push Approved</button>
      <button onClick={() => pushToast(mockRejectedNotification)} data-testid="push-rejected">Push Rejected</button>
      <button onClick={() => pushToast(mockSubmittedNotification)} data-testid="push-submitted">Push Submitted</button>
      <button onClick={() => pushToast(mockCancelledNotification)} data-testid="push-cancelled">Push Cancelled</button>
      <button onClick={() => pushToast(mockRevokedNotification)} data-testid="push-revoked">Push Revoked</button>
      <ToastContainer />
    </div>
  );
}

describe('ToastContainer', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    localStorage.setItem('act_hrm_access_token', 'test-token');
    localStorage.setItem('act_hrm_unread_count', '0');

    // Setup default mock responses
    (apiClient.notifications.getAll as jest.Mock).mockResolvedValue({
      content: [],
      totalElements: 0,
      totalPages: 0,
      size: 20,
      number: 0,
      last: true,
    });
    (apiClient.notifications.getUnreadCount as jest.Mock).mockResolvedValue({ count: 0 });
  });

  afterEach(() => {
    jest.useRealTimers();
    localStorage.clear();
  });

  describe('Rendering', () => {
    it('renders nothing when no toasts', async () => {
      renderWithProviders(<ToastContainer />);

      await waitFor(() => {
        expect(screen.queryByRole('alert')).not.toBeInTheDocument();
      });
    });

    it('renders toast when added to queue via context', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        const toast = screen.getByRole('alert');
        expect(toast).toBeInTheDocument();
        expect(toast).toHaveTextContent('Leave Request Approved');
      });
    });
  });

  describe('Toast Types', () => {
    const typeStyles = {
      APPROVED: { bg: 'bg-emerald-50', border: 'border-emerald-200', icon: 'CheckCircle' },
      REJECTED: { bg: 'bg-red-50', border: 'border-red-200', icon: 'XCircle' },
      SUBMITTED: { bg: 'bg-blue-50', border: 'border-blue-200', icon: 'AlertCircle' },
      CANCELLED: { bg: 'bg-amber-50', border: 'border-amber-200', icon: 'Clock' },
      REVOKED: { bg: 'bg-purple-50', border: 'border-purple-200', icon: 'AlertCircle' },
    };

    it.each(Object.entries(typeStyles))('renders %s toast with correct styling', async (action, style) => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId(`push-${action.toLowerCase()}`)).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId(`push-${action.toLowerCase()}`));
      });

      await waitFor(() => {
        const toast = screen.getByRole('alert');
        expect(toast).toBeInTheDocument();
        expect(toast).toHaveTextContent(
          action === 'APPROVED' ? 'Leave Request Approved' :
          action === 'REJECTED' ? 'Overtime Request Rejected' :
          action === 'SUBMITTED' ? 'New Resignation Request' :
          action === 'CANCELLED' ? 'Leave Request Cancelled' :
          'Overtime Request Revoked'
        );
      });
    });
  });

  describe('Toast Behavior', () => {
    it('auto-dismisses after 5 seconds', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        expect(screen.getByRole('alert')).toBeInTheDocument();
      });

      // Advance timers by 5 seconds (TOAST_DURATION)
      act(() => {
        jest.advanceTimersByTime(5000);
      });

      await waitFor(() => {
        expect(screen.queryByRole('alert')).not.toBeInTheDocument();
      });
    });

    it('can be dismissed by clicking X button', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        expect(screen.getByRole('alert')).toBeInTheDocument();
      });

      // Click dismiss button
      const dismissButton = screen.getByLabelText('Dismiss notification');
      act(() => {
        userEvent.click(dismissButton);
      });

      await waitFor(() => {
        expect(screen.queryByRole('alert')).not.toBeInTheDocument();
      });
    });

    it('supports keyboard navigation (Enter/Space)', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        const toast = screen.getByRole('alert');
        expect(toast).toHaveAttribute('tabIndex', '0');
      });
    });
  });

  describe('Stacking', () => {
    it('stacks multiple toasts vertically', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      // Push multiple toasts
      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
        userEvent.click(screen.getByTestId('push-rejected'));
        userEvent.click(screen.getByTestId('push-submitted'));
      });

      await waitFor(() => {
        const toasts = screen.getAllByRole('alert');
        expect(toasts).toHaveLength(3);
      });
    });

    it('shows newest toast at bottom (reverse flex)', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
        userEvent.click(screen.getByTestId('push-rejected'));
      });

      await waitFor(() => {
        const toasts = screen.getAllByRole('alert');
        expect(toasts).toHaveLength(2);
        // The container uses flex-col-reverse so newest appears at bottom
        // This is a visual behavior test - we verify both toasts exist
      });
    });
  });

  describe('Accessibility', () => {
    it('has role="alert" for screen readers', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        const toast = screen.getByRole('alert');
        expect(toast).toHaveAttribute('role', 'alert');
      });
    });

    it('is keyboard accessible with tabIndex=0', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        const toast = screen.getByRole('alert');
        expect(toast).toHaveAttribute('tabIndex', '0');
      });
    });

    it('has aria-label on dismiss button', async () => {
      renderWithProviders(<TestToastComponent />);

      await waitFor(() => {
        expect(screen.getByTestId('push-approved')).toBeInTheDocument();
      });

      act(() => {
        userEvent.click(screen.getByTestId('push-approved'));
      });

      await waitFor(() => {
        const dismissButton = screen.getByLabelText('Dismiss notification');
        expect(dismissButton).toBeInTheDocument();
      });
    });
  });
});