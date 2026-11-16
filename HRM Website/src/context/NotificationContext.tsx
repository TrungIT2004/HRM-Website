'use client';

import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { Notification, ToastNotification } from '@/types';
import { apiClient } from '@/services/apiClient';

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  toasts: ToastNotification[];
  isConnected: boolean;
  connect: () => void;
  disconnect: () => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
  pushToast: (notification: Notification) => void;
  removeToast: (id: string) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

const TOAST_DURATION = 5000;
const NOTIFICATIONS_ENABLED = process.env.NEXT_PUBLIC_ENABLE_NOTIFICATIONS === 'true';

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [toasts, setToasts] = useState<ToastNotification[]>([]);
  const [isConnected, setIsConnected] = useState(false);

  const eventSourceRef = useRef<EventSource | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const reconnectAttempts = useRef(0);
  const maxReconnectAttempts = 5;

  const fetchInitialData = useCallback(async () => {
    try {
      const [notificationsRes, countRes] = await Promise.all([
        apiClient.notifications.getAll(0, 20, false),
        apiClient.notifications.getUnreadCount()
      ]);
      setNotifications(notificationsRes.content);
      setUnreadCount(countRes.count);
    } catch (error) {
      console.error('Failed to fetch initial notifications:', error);
    }
  }, []);

  const connect = useCallback(() => {
    if (eventSourceRef.current) {
      return; // Already connected
    }

    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    if (!token) {
      console.warn('No auth token, skipping SSE connection');
      return;
    }

    const url = apiClient.notifications.streamUrl();
    const eventSource = new EventSource(url, { withCredentials: true });
    eventSourceRef.current = eventSource;

    eventSource.onopen = () => {
      console.log('SSE connected');
      setIsConnected(true);
      reconnectAttempts.current = 0;
    };

    eventSource.addEventListener('notification', (event) => {
      try {
        const notification: Notification = JSON.parse(event.data);

        // Add to notifications list (avoid duplicates)
        setNotifications(prev => {
          const exists = prev.some(n => n.notificationId === notification.notificationId);
          if (exists) return prev;
          return [notification, ...prev].slice(0, 100); // Keep latest 100
        });

        // Update unread count
        setUnreadCount(prev => prev + 1);

        // Push toast for real-time notification
        pushToast(notification);
      } catch (error) {
        console.error('Failed to parse notification event:', error);
      }
    });

    eventSource.addEventListener('unread_count', (event) => {
      try {
        const data = JSON.parse(event.data);
        setUnreadCount(data.count);
        // Persist to localStorage for tab badge
        if (typeof window !== 'undefined') {
          localStorage.setItem('act_hrm_unread_count', String(data.count));
        }
      } catch (error) {
        console.error('Failed to parse unread_count event:', error);
      }
    });

    eventSource.addEventListener('heartbeat', () => {
      // Keep connection alive
    });

    eventSource.onerror = (error) => {
      console.error('SSE error:', error);
      setIsConnected(false);
      eventSource.close();
      eventSourceRef.current = null;

      // Attempt reconnection with exponential backoff
      if (reconnectAttempts.current < maxReconnectAttempts) {
        const delay = Math.min(1000 * Math.pow(2, reconnectAttempts.current), 30000);
        reconnectAttempts.current++;
        reconnectTimeoutRef.current = setTimeout(() => {
          connect();
        }, delay);
      }
    };
  }, []);

  const disconnect = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
      eventSourceRef.current = null;
    }
    setIsConnected(false);
    reconnectAttempts.current = 0;
  }, []);

  const pushToast = useCallback((notification: Notification) => {
    const toastId = `toast-${notification.notificationId}-${Date.now()}`;
    const newToast: ToastNotification = {
      id: toastId,
      notification,
      visible: true
    };

    setToasts(prev => [...prev, newToast]);

    // Auto-dismiss after duration
    setTimeout(() => {
      removeToast(toastId);
    }, TOAST_DURATION);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const markAsRead = useCallback(async (id: string) => {
    // Optimistic update
    setNotifications(prev => prev.map(n =>
      n.notificationId === id ? { ...n, isRead: true } : n
    ));
    setUnreadCount(prev => Math.max(0, prev - 1));

    try {
      await apiClient.notifications.markAsRead(id);
    } catch (error) {
      console.error('Failed to mark notification as read:', error);
      // Revert on error
      setNotifications(prev => prev.map(n =>
        n.notificationId === id ? { ...n, isRead: false } : n
      ));
      setUnreadCount(prev => prev + 1);
    }
  }, []);

  const markAllAsRead = useCallback(async () => {
    // Optimistic update
    setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
    setUnreadCount(0);

    try {
      await apiClient.notifications.markAllAsRead();
    } catch (error) {
      console.error('Failed to mark all notifications as read:', error);
      // Revert would require refetching - just refresh
      fetchInitialData();
    }
  }, [fetchInitialData]);

  // Connect on mount, disconnect on unmount
  useEffect(() => {
    if (!NOTIFICATIONS_ENABLED) return;

    // Restore unread count from localStorage for tab badge
    if (typeof window !== 'undefined') {
      const savedCount = localStorage.getItem('act_hrm_unread_count');
      if (savedCount) {
        setUnreadCount(parseInt(savedCount, 10));
      }
    }

    fetchInitialData();
    connect();

    return () => {
      disconnect();
    };
  }, [fetchInitialData, connect, disconnect]);

  return (
    <NotificationContext.Provider value={{
      notifications,
      unreadCount,
      toasts,
      isConnected,
      connect,
      disconnect,
      markAsRead,
      markAllAsRead,
      pushToast,
      removeToast
    }}>
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotifications() {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
}