import { apiClient } from './apiClient';
import { Notification, NotificationPage, NotificationType } from '@/types';

export interface NotificationFilters {
  page?: number;
  size?: number;
  type?: NotificationType;
  readStatus?: 'ALL' | 'UNREAD' | 'READ';
}

export const notificationService = {
  async getNotifications(filters: NotificationFilters = {}): Promise<NotificationPage> {
    const params = new URLSearchParams();
    if (filters.page !== undefined) params.set('page', filters.page.toString());
    if (filters.size !== undefined) params.set('size', filters.size.toString());
    if (filters.type) params.set('type', filters.type);
    if (filters.readStatus) params.set('readStatus', filters.readStatus);

    return apiClient.get<NotificationPage>(`/api/notifications?${params.toString()}`);
  },

  async getUnreadCount(): Promise<{ count: number }> {
    return apiClient.get<{ count: number }>('/api/notifications/unread-count');
  },

  async markRead(notificationId: string): Promise<void> {
    await apiClient.patch(`/api/notifications/${notificationId}/read`);
  },

  async markAllRead(): Promise<void> {
    await apiClient.patch('/api/notifications/read-all');
  },

  async getNotification(notificationId: string): Promise<Notification> {
    return apiClient.get<Notification>(`/api/notifications/${notificationId}`);
  },
};