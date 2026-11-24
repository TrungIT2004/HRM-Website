'use client';

import React, { createContext, useContext, ReactNode } from 'react';
import { Notification, NotificationPage, NotificationType } from '@/types';
import { useNotificationsWebSocket } from '@/hooks/useNotificationsWebSocket';

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  isConnected: boolean;
  markRead: (notificationId: string) => Promise<void>;
  markAllRead: () => Promise<void>;
  fetchPage: (page: number, filters?: { type?: NotificationType; readStatus?: 'ALL' | 'UNREAD' | 'READ' }) => Promise<NotificationPage>;
  fetchUnreadCount: () => Promise<void>;
  loadInitialNotifications: () => Promise<void>;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export function NotificationProvider({ children }: { children: ReactNode }) {
  const value = useNotificationsWebSocket();

  return (
    <NotificationContext.Provider value={value}>
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