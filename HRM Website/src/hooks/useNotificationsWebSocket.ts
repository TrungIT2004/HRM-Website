'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { Client, Message } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import { Notification, NotificationPage, NotificationType } from '@/types';
import { notificationService } from '@/services/notificationService';
import { useAuth } from '@/context/AuthContext';

interface WebSocketNotificationPayload {
  notificationId: string;
  type: NotificationType;
  title: string;
  body: string;
  referenceId: string;
  referenceType: string;
  priority: 'HIGH' | 'NORMAL';
  metadata: Record<string, any>;
  createdAt: string;
}

interface WebSocketMessage {
  type: string;
  payload: WebSocketNotificationPayload | { count: number };
}

export function useNotificationsWebSocket() {
  const { currentUser } = useAuth();
  const clientRef = useRef<Client | null>(null);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isConnected, setIsConnected] = useState(false);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const initialLoadDone = useRef(false);

  const connect = useCallback(() => {
    if (!currentUser) return;

    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    if (!token) return;

    // Clean up existing connection
    if (clientRef.current?.connected) {
      clientRef.current.deactivate();
    }

    const client = new Client({
      webSocketFactory: () => new SockJS(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'}/ws/notifications`),
      connectHeaders: {
        Authorization: `Bearer ${token}`,
      },
      reconnectDelay: 5000,
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
      debug: (str) => {
        if (process.env.NODE_ENV === 'development') {
          console.log('[STOMP]', str);
        }
      },
      onConnect: () => {
        setIsConnected(true);
        console.log('[Notifications] WebSocket connected');

        // Subscribe to user-specific queue
        client.subscribe('/user/queue/notifications', (message: Message) => {
          try {
            const wsMessage: WebSocketMessage = JSON.parse(message.body);
            handleWebSocketMessage(wsMessage);
          } catch (e) {
            console.error('[Notifications] Failed to parse message:', e);
          }
        });

        // Fetch initial unread count
        fetchUnreadCount();

        // Load initial notifications for dropdown (latest 4)
        if (!initialLoadDone.current) {
          initialLoadDone.current = true;
          loadInitialNotifications();
        }
      },
      onDisconnect: () => {
        setIsConnected(false);
        console.log('[Notifications] WebSocket disconnected');
        scheduleReconnect();
      },
      onStompError: (frame) => {
        console.error('[Notifications] STOMP error:', frame.headers['message'], frame.body);
      },
    });

    clientRef.current = client;
    client.activate();
  }, [currentUser]);

  const handleWebSocketMessage = (message: WebSocketMessage) => {
    if (message.type === 'NOTIFICATION_CREATED' && message.payload && 'notificationId' in message.payload) {
      const payload = message.payload as WebSocketNotificationPayload;
      const newNotification: Notification = {
        notificationId: payload.notificationId,
        type: payload.type,
        title: payload.title,
        body: payload.body,
        referenceId: payload.referenceId,
        referenceType: payload.referenceType as Notification['referenceType'],
        priority: payload.priority,
        metadata: payload.metadata,
        readAt: null,
        createdAt: payload.createdAt,
      };

      setNotifications(prev => {
        // Avoid duplicates
        if (prev.some(n => n.notificationId === newNotification.notificationId)) {
          return prev;
        }
        return [newNotification, ...prev].slice(0, 4); // Keep only latest 4 for dropdown
      });

      setUnreadCount(prev => prev + 1);
    } else if (message.type === 'UNREAD_COUNT' && message.payload && 'count' in message.payload) {
      setUnreadCount((message.payload as { count: number }).count);
    }
  };

  const fetchUnreadCount = async () => {
    try {
      const { count } = await notificationService.getUnreadCount();
      setUnreadCount(count);
    } catch (e) {
      console.error('[Notifications] Failed to fetch unread count:', e);
    }
  };

  const loadInitialNotifications = async () => {
    try {
      const page = await notificationService.getNotifications({ page: 0, size: 4 });
      setNotifications(page.content);
    } catch (e) {
      console.error('[Notifications] Failed to load initial notifications:', e);
    }
  };

  const scheduleReconnect = () => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
    }
    reconnectTimeoutRef.current = setTimeout(() => {
      if (currentUser) {
        connect();
      }
    }, 5000);
  };

  const markRead = useCallback(async (notificationId: string) => {
    try {
      await notificationService.markRead(notificationId);
      setNotifications(prev => prev.map(n =>
        n.notificationId === notificationId ? { ...n, readAt: new Date().toISOString() } : n
      ));
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (e) {
      console.error('[Notifications] Failed to mark read:', e);
    }
  }, []);

  const markAllRead = useCallback(async () => {
    try {
      await notificationService.markAllRead();
      setNotifications(prev => prev.map(n => ({ ...n, readAt: new Date().toISOString() })));
      setUnreadCount(0);
    } catch (e) {
      console.error('[Notifications] Failed to mark all read:', e);
    }
  }, []);

  const fetchPage = useCallback(async (page: number, filters: { type?: NotificationType; readStatus?: 'ALL' | 'UNREAD' | 'READ' } = {}) => {
    return notificationService.getNotifications({ page, size: 10, ...filters });
  }, []);

  // Connect on mount and when user/token changes
  useEffect(() => {
    connect();

    // Listen for token changes (login/logout)
    const handleTokenChange = () => {
      initialLoadDone.current = false;
      connect();
    };
    window.addEventListener('act-hrm:token-changed', handleTokenChange);

    const handleLogout = () => {
      if (clientRef.current?.connected) {
        clientRef.current.deactivate();
      }
      setNotifications([]);
      setUnreadCount(0);
      setIsConnected(false);
      initialLoadDone.current = false;
    };
    window.addEventListener('act-hrm:logout', handleLogout);

    return () => {
      window.removeEventListener('act-hrm:token-changed', handleTokenChange);
      window.removeEventListener('act-hrm:logout', handleLogout);
      if (clientRef.current?.connected) {
        clientRef.current.deactivate();
      }
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
    };
  }, [connect]);

  return {
    notifications,
    unreadCount,
    isConnected,
    markRead,
    markAllRead,
    fetchPage,
    fetchUnreadCount,
    loadInitialNotifications,
  };
}