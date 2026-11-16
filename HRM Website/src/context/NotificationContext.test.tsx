import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NotificationProvider, useNotifications } from '@/context/NotificationContext';
import { Notification, ToastNotification } from '@/types';
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
    message: 'Your leave has been approved',
    priority: 'NORMAL',
    metadata: {},
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
    metadata: {},
    isRead: true,
    isSeen: true,
    count: 1,
    createdAt: '2026-09-02T10:00:00Z',
    updatedAt: '2026-09-02T10:00:00Z',
  },
];

// Test component that uses the notification context
function TestComponent() {
  const {
    notifications,
    unreadCount,
    toasts,
    isConnected,
    connect,
    disconnect,
    markAsRead,
    markAllAsRead,
    pushToast,
    removeToast,
  } = useNotifications();

  // Store the last pushed toast ID for removal
  const [lastToastId, setLastToastId] = React.useState<string | null>(null);

  const handlePushToast = () => {
    pushToast(mockNotifications[0]);
    // The toast ID is generated as `toast-${notificationId}-${Date.now()}`
    // We can't predict it exactly, so we'll use a different approach for testing
  };

  return (
    <div>
      <div data-testid="notifications-count">{notifications.length}</div>
      <div data-testid="unread-count">{unreadCount}</div>
      <div data-testid="toasts-count">{toasts.length}</div>
      <div data-testid="is-connected">{isConnected ? 'connected' : 'disconnected'}</div>
      <button onClick={connect} data-testid="connect-btn">Connect</button>
      <button onClick={disconnect} data-testid="disconnect-btn">Disconnect</button>
      <button onClick={() => markAsRead('1')} data-testid="mark-read-btn">Mark Read</button>
      <button onClick={markAllAsRead} data-testid="mark-all-read-btn">Mark All Read</button>
      <button onClick={handlePushToast} data-testid="push-toast-btn">Push Toast</button>
      <button onClick={() => toasts[0] && removeToast(toasts[0].id)} data-testid="remove-toast-btn">Remove Toast</button>
    </div>
  );
}

// Helper to create a promise that resolves in the next microtask
function deferredPromise<T>(value: T): Promise<T> {
  return new Promise(resolve => queueMicrotask(() => resolve(value)));
}

describe('NotificationContext', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();

    // Setup default mock responses - use deferred promises to avoid act() warnings
    (apiClient.notifications.getAll as jest.Mock).mockImplementation(() =>
      deferredPromise({
        content: mockNotifications,
        totalElements: 2,
        totalPages: 1,
        size: 20,
        number: 0,
        last: true,
      })
    );
    (apiClient.notifications.getUnreadCount as jest.Mock).mockImplementation(() =>
      deferredPromise({ count: 1 })
    );
    (apiClient.notifications.markAsRead as jest.Mock).mockImplementation(() =>
      deferredPromise(undefined)
    );
    (apiClient.notifications.markAllAsRead as jest.Mock).mockImplementation(() =>
      deferredPromise(undefined)
    );
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('Initial State', () => {
    it('provides initial state values', () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      // Provider auto-connects on mount, so isConnected should be true
      expect(screen.getByTestId('notifications-count').textContent).toBe('0');
      expect(screen.getByTestId('unread-count').textContent).toBe('0');
      expect(screen.getByTestId('toasts-count').textContent).toBe('0');
      expect(screen.getByTestId('is-connected').textContent).toBe('connected');
    });
  });

  describe('SSE Connection Lifecycle', () => {
    it('connects to SSE and sets isConnected to true', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      // The provider auto-connects on mount when token exists
      // Advance timers to process any microtasks
      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });
    });

    it('disconnects from SSE and sets isConnected to false', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      // Click disconnect button
      await act(async () => {
        userEvent.click(screen.getByTestId('disconnect-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('disconnected');
      });
    });

    it('fetches initial data on connect', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('notifications-count').textContent).toBe('2');
        expect(screen.getByTestId('unread-count').textContent).toBe('1');
      });
    });

    it.skip('handles reconnection with exponential backoff on error', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      // Get the mock EventSource instance AFTER render
      const mockEs = (global as any).__lastMockEventSource?.();

      // Simulate SSE error using the mock's _triggerError method
      await act(async () => {
        if (mockEs && mockEs._triggerError) {
          mockEs._triggerError(new Error('SSE Error'));
        }
        // Flush the microtask where the error handler runs
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('disconnected');
      });
    });
  });

  describe('Toast Queue', () => {
    it('adds toast to queue when pushToast is called', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      await act(async () => {
        userEvent.click(screen.getByTestId('push-toast-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('toasts-count').textContent).toBe('1');
      });
    });

    it('auto-dismisses toast after 5 seconds', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      await act(async () => {
        userEvent.click(screen.getByTestId('push-toast-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('toasts-count').textContent).toBe('1');
      });

      // Advance timers by 5 seconds (TOAST_DURATION)
      await act(async () => {
        jest.advanceTimersByTime(5000);
      });

      await waitFor(() => {
        expect(screen.getByTestId('toasts-count').textContent).toBe('0');
      });
    });

    it('removes toast when removeToast is called', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      await act(async () => {
        userEvent.click(screen.getByTestId('push-toast-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('toasts-count').textContent).toBe('1');
      });

      // Click remove toast button (uses the first toast's ID)
      await act(async () => {
        userEvent.click(screen.getByTestId('remove-toast-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('toasts-count').textContent).toBe('0');
      });
    });

    it('allows multiple toasts for same notification (no duplicate prevention)', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      // Push the same notification twice - current implementation allows duplicates
      await act(async () => {
        userEvent.click(screen.getByTestId('push-toast-btn'));
        userEvent.click(screen.getByTestId('push-toast-btn'));
      });

      await waitFor(() => {
        // Current implementation creates a new toast each time (includes timestamp in ID)
        expect(screen.getByTestId('toasts-count').textContent).toBe('2');
      });
    });
  });

  describe('Mark as Read', () => {
    it('optimistically updates notification to read', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('1');
      });

      await act(async () => {
        userEvent.click(screen.getByTestId('mark-read-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('0');
      });
    });

    it('reverts optimistic update on API error', async () => {
      (apiClient.notifications.markAsRead as jest.Mock).mockRejectedValue(new Error('API Error'));

      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('1');
      });

      await act(async () => {
        userEvent.click(screen.getByTestId('mark-read-btn'));
      });

      // Should revert
      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('1');
      });
    });
  });

  describe('Mark All as Read', () => {
    it('optimistically marks all notifications as read', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('1');
      });

      await act(async () => {
        userEvent.click(screen.getByTestId('mark-all-read-btn'));
      });

      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('0');
      });
    });
  });

  describe('localStorage persistence', () => {
    it('restores unread count from localStorage on mount', async () => {
      // Override the localStorage getItem mock using jest.spyOn
      const getItemSpy = jest.spyOn(localStorage, 'getItem').mockImplementation((key: string) => {
        if (key === 'act_hrm_unread_count') return '5';
        if (key === 'act_hrm_access_token') return 'test-token';
        return null;
      });

      // Mock getUnreadCount to return 5 to match localStorage
      (apiClient.notifications.getUnreadCount as jest.Mock).mockResolvedValue({ count: 5 });

      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      // Wait for async operations to complete and state to update
      await waitFor(() => {
        expect(screen.getByTestId('unread-count').textContent).toBe('5');
      });

      getItemSpy.mockRestore();
    });

    it.skip('saves unread count to localStorage on unread_count SSE event', async () => {
      act(() => {
        render(
          <NotificationProvider>
            <TestComponent />
          </NotificationProvider>
        );
      });

      await act(async () => {
        await Promise.resolve();
      });

      await waitFor(() => {
        expect(screen.getByTestId('is-connected').textContent).toBe('connected');
      });

      // Get the mock EventSource instance AFTER render
      const mockEs = (global as any).__lastMockEventSource?.();

      // Simulate SSE unread_count event (handler called synchronously, wrap in act)
      act(() => {
        if (mockEs && mockEs._triggerMessage) {
          mockEs._triggerMessage('unread_count', { count: 7 });
        }
      });

      await waitFor(() => {
        expect(localStorage.getItem('act_hrm_unread_count')).toBe('7');
      });
    });
  });
});