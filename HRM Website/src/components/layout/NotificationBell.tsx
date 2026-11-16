'use client';

import React, { useState, useEffect, useRef } from 'react';
import { Bell, Check, X, Loader2, ExternalLink } from 'lucide-react';
import { useNotifications } from '@/context/NotificationContext';
import { Notification } from '@/types';
import { apiClient } from '@/services/apiClient';
import { formatDistanceToNow } from 'date-fns';

interface NotificationBellProps {
  unreadCount: number;
}

export default function NotificationBell({ unreadCount }: NotificationBellProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const { markAsRead, markAllAsRead } = useNotifications();

  // Fetch notifications when dropdown opens
  useEffect(() => {
    if (isOpen && notifications.length === 0) {
      loadNotifications();
    }
  }, [isOpen]);

  const loadNotifications = async (pageNum = 0, append = false) => {
    setLoading(true);
    try {
      const res = await apiClient.notifications.getAll(pageNum, 20, false);
      if (append) {
        setNotifications(prev => [...prev, ...res.content]);
      } else {
        setNotifications(res.content);
      }
      setHasMore(!res.last);
      setPage(pageNum);
    } catch (error) {
      console.error('Failed to load notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (notification: Notification) => {
    if (!notification.isRead) {
      await markAsRead(notification.notificationId);
      setNotifications(prev => prev.map(n =>
        n.notificationId === notification.notificationId ? { ...n, isRead: true } : n
      ));
    }
  };

  const handleMarkAllAsRead = async () => {
    await markAllAsRead();
    setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
  };

  const handleNotificationClick = (notification: Notification) => {
    handleMarkAsRead(notification);
    // Navigate to request detail
    const routes: Record<string, string> = {
      LEAVE: `/leave/${notification.requestId}`,
      OVERTIME: `/overtime/${notification.requestId}`,
      RESIGNATION: `/resignation/${notification.requestId}`,
      ASSET_REQUEST: `/asset-request/${notification.requestId}`,
      GENERIC: '/notifications'
    };
    const route = routes[notification.requestType] || '/notifications';
    window.location.href = route;
    setIsOpen(false);
  };

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const target = e.currentTarget;
    if (target.scrollTop + target.clientHeight >= target.scrollHeight - 100 && !loading && hasMore) {
      loadNotifications(page + 1, true);
    }
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  const unreadNotifications = notifications.filter(n => !n.isRead).length;

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 rounded-lg hover:bg-slate-100 transition-colors text-slate-600 hover:text-slate-900"
        aria-label={`Notifications${unreadCount > 0 ? `, ${unreadCount} unread` : ''}`}
        data-testid="notification-bell"
      >
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span
            className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-white text-[10px] font-bold"
            data-testid="notification-badge"
          >
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-96 bg-white rounded-xl shadow-xl ring-1 ring-black/5 z-50 animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100">
            <h3 className="font-semibold text-slate-900">Thông báo</h3>
            {unreadNotifications > 0 && (
              <button
                onClick={handleMarkAllAsRead}
                className="text-xs font-medium text-blue-600 hover:text-blue-700"
              >
                Đánh dấu tất cả đã đọc
              </button>
            )}
          </div>

          {/* Notification List */}
          <div
            className="max-h-96 overflow-y-auto"
            onScroll={handleScroll}
          >
            {loading && notifications.length === 0 && (
              <div className="flex items-center justify-center py-8" data-testid="loading-spinner">
                <Loader2 className="h-6 w-6 animate-spin text-slate-400" />
              </div>
            )}

            {notifications.length === 0 && !loading && (
              <div className="py-8 text-center text-slate-500">
                <Bell className="h-10 w-10 mx-auto text-slate-300 mb-2" />
                <p>Không có thông báo nào</p>
              </div>
            )}

            <div className="divide-y divide-slate-100" data-testid="notification-list">
              {notifications.map((notification) => (
                <button
                  key={notification.notificationId}
                  onClick={() => handleNotificationClick(notification)}
                  className={`w-full px-4 py-3 text-left hover:bg-slate-50 transition-colors ${
                    !notification.isRead ? 'bg-blue-50' : ''
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
                      notification.action === 'APPROVED' ? 'bg-emerald-100 text-emerald-600' :
                      notification.action === 'REJECTED' ? 'bg-red-100 text-red-600' :
                      notification.action === 'SUBMITTED' ? 'bg-blue-100 text-blue-600' :
                      'bg-amber-100 text-amber-600'
                    }`}>
                      {notification.action === 'APPROVED' && <Check className="h-4 w-4" />}
                      {notification.action === 'REJECTED' && <X className="h-4 w-4" />}
                      {notification.action === 'SUBMITTED' && <Bell className="h-4 w-4" />}
                      {notification.action === 'CANCELLED' && <X className="h-4 w-4" />}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <p className={`font-medium text-sm ${!notification.isRead ? 'text-slate-900' : 'text-slate-700'}`}>
                          {notification.title}
                        </p>
                        {!notification.isRead && (
                          <span className="flex-shrink-0 w-1.5 h-1.5 rounded-full bg-blue-500 mt-1.5" />
                        )}
                      </div>
                      <p className="text-sm text-slate-500 mt-1 line-clamp-1">{notification.message}</p>
                      <p className="text-xs text-slate-400 mt-1">
                        {formatDistanceToNow(new Date(notification.createdAt), { addSuffix: true })}
                      </p>
                    </div>
                  </div>
                </button>
              ))}
            </div>

            {!hasMore && notifications.length > 0 && (
              <div className="px-4 py-2 text-center text-xs text-slate-400">
                Đã hết thông báo
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="px-4 py-2 border-t border-slate-100">
            <a
              href="/notifications"
              className="block text-center text-sm font-medium text-blue-600 hover:text-blue-700"
              onClick={() => setIsOpen(false)}
            >
              Xem tất cả thông báo
              <ExternalLink className="inline h-3 w-3 ml-1" />
            </a>
          </div>
        </div>
      )}
    </div>
  );
}