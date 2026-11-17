'use client';

import React, { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { X, Calendar, Clock, UserX, Package, Wrench, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';
import { useNotifications } from '@/components/providers/NotificationProvider';
import { Notification, NotificationType } from '@/types';

const typeIcons = {
  LEAVE: Calendar,
  OVERTIME: Clock,
  RESIGNATION: UserX,
  ASSET: Package,
  IT_TICKET: Wrench,
} as const;

const typeColors = {
  LEAVE: 'bg-blue-100 text-blue-600 border-blue-200',
  OVERTIME: 'bg-amber-100 text-amber-600 border-amber-200',
  RESIGNATION: 'bg-red-100 text-red-600 border-red-200',
  ASSET: 'bg-purple-100 text-purple-600 border-purple-200',
  IT_TICKET: 'bg-emerald-100 text-emerald-600 border-emerald-200',
} as const;

function getTypeIcon(type: NotificationType) {
  return typeIcons[type];
}

function getTypeColor(type: NotificationType) {
  return typeColors[type];
}

function routeFor(referenceType: string, referenceId: string): string {
  switch (referenceType) {
    case 'LEAVE_REQUEST':
      return `/leave/requests/${referenceId}`;
    case 'OVERTIME_RECORD':
      return `/overtime/requests/${referenceId}`;
    case 'RESIGNATION_REQUEST':
      return `/resignations/${referenceId}`;
    case 'ASSET_REQUEST':
      return `/assets/requests/${referenceId}`;
    case 'IT_TICKET':
      return `/it/tickets/${referenceId}`;
    default:
      return '/notifications';
  }
}

interface ToastItem {
  notification: Notification;
  id: number; // Unique ID for React key
}

export function NotificationToasts() {
  const { notifications, markRead, isConnected } = useNotifications();
  const router = useRouter();
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const toastIdCounter = useRef(0);
  const timersRef = useRef<Map<string, NodeJS.Timeout>>(new Map());
  const processedNotificationsRef = useRef<Set<string>>(new Set());

  // Check if current page is the detail page for a notification
  const isOnDetailPage = (notification: Notification) => {
    if (typeof window === 'undefined') return false;
    const path = window.location.pathname;
    const detailPath = routeFor(notification.referenceType, notification.referenceId);
    return path === detailPath || path.startsWith(detailPath + '/');
  };

  // Process new notifications from WebSocket
  useEffect(() => {
    if (!isConnected) return;

    for (const notification of notifications) {
      // Skip if already processed or if on detail page
      if (processedNotificationsRef.current.has(notification.notificationId)) continue;
      if (isOnDetailPage(notification)) continue;

      // Add to toasts (max 3)
      if (toasts.length < 3) {
        const newToast: ToastItem = {
          notification,
          id: ++toastIdCounter.current,
        };
        setToasts(prev => [...prev, newToast]);
        processedNotificationsRef.current.add(notification.notificationId);

        // Auto-dismiss after 5 seconds
        const timer = setTimeout(() => {
          removeToast(newToast.id);
        }, 5000);
        timersRef.current.set(notification.notificationId, timer);
      }
    }
  }, [notifications, isConnected, toasts.length]);

  // Cleanup timers on unmount
  useEffect(() => {
    return () => {
      for (const timer of timersRef.current.values()) {
        clearTimeout(timer);
      }
    };
  }, []);

  const removeToast = (id: number) => {
    setToasts(prev => {
      const toast = prev.find(t => t.id === id);
      if (toast) {
        const timer = timersRef.current.get(toast.notification.notificationId);
        if (timer) {
          clearTimeout(timer);
          timersRef.current.delete(toast.notification.notificationId);
        }
      }
      return prev.filter(t => t.id !== id);
    });
  };

  const handleToastClick = async (toast: ToastItem) => {
    if (!toast.notification.readAt) {
      await markRead(toast.notification.notificationId);
    }
    router.push(routeFor(toast.notification.referenceType, toast.notification.referenceId));
    removeToast(toast.id);
  };

  const handleCloseClick = (e: React.MouseEvent, id: number) => {
    e.stopPropagation();
    removeToast(id);
  };

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-[100] flex flex-col-reverse gap-2 pointer-events-none">
      {toasts.map((toast) => (
        <div
          key={toast.id}
          onClick={() => handleToastClick(toast)}
          onMouseEnter={() => {
            const timer = timersRef.current.get(toast.notification.notificationId);
            if (timer) clearTimeout(timer);
          }}
          onMouseLeave={() => {
            const timer = setTimeout(() => removeToast(toast.id), 3000);
            timersRef.current.set(toast.notification.notificationId, timer);
          }}
          className={`pointer-events-auto flex items-start gap-3 w-96 ${getTypeColor(toast.notification.type)} rounded-xl border shadow-xl p-3 animate-in slide-in-from-right-4`}
          role="alert"
          aria-live="polite"
        >
          {(() => { const Icon = getTypeIcon(toast.notification.type); return <Icon className="h-5 w-5 shrink-0 mt-0.5" />; })()}
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-slate-900">{toast.notification.title}</p>
            <p className="mt-0.5 text-sm text-slate-600 line-clamp-2">{toast.notification.body}</p>
            <p className="mt-1.5 text-xs text-slate-400">
              {formatDistanceToNow(new Date(toast.notification.createdAt), { addSuffix: true, locale: vi })}
            </p>
          </div>
          <button
            onClick={(e) => handleCloseClick(e, toast.id)}
            className="shrink-0 p-1 rounded-lg hover:bg-white/50 transition-colors"
            aria-label="Đóng"
          >
            <X className="h-4 w-4 text-slate-500" />
          </button>
        </div>
      ))}
    </div>
  );
}