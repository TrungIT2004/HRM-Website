'use client';

import React, { useRef, useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Bell, Calendar, Clock, UserX, Package, Wrench, ExternalLink, Loader2 } from 'lucide-react';
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
  LEAVE: 'bg-blue-100 text-blue-600',
  OVERTIME: 'bg-amber-100 text-amber-600',
  RESIGNATION: 'bg-red-100 text-red-600',
  ASSET: 'bg-purple-100 text-purple-600',
  IT_TICKET: 'bg-emerald-100 text-emerald-600',
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

export function NotificationBell() {
  const { notifications, unreadCount, markRead, isConnected } = useNotifications();
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const bellRef = useRef<HTMLButtonElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node) &&
          bellRef.current && !bellRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Close on Escape
  useEffect(() => {
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setIsOpen(false);
      }
    }
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, []);

  const handleNotificationClick = async (notification: Notification) => {
    if (!notification.readAt) {
      await markRead(notification.notificationId);
    }
    router.push(routeFor(notification.referenceType, notification.referenceId));
    setIsOpen(false);
  };

  const handleShowAllClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    router.push('/notifications');
    setIsOpen(false);
  };

  const toggleDropdown = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsOpen(!isOpen);
  };

  const displayCount = unreadCount > 9 ? '9+' : unreadCount.toString();

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        ref={bellRef}
        onClick={toggleDropdown}
        className={`relative flex items-center justify-center p-2 rounded-xl transition-colors ${
          unreadCount > 0
            ? 'bg-blue-50 text-blue-600 hover:bg-blue-100'
            : 'text-slate-500 hover:bg-slate-100 hover:text-slate-700'
        }`}
        aria-label={`Thông báo${unreadCount > 0 ? `, ${unreadCount} chưa đọc` : ''}`}
        aria-expanded={isOpen}
      >
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center text-[10px] font-bold leading-none text-white transform transition-all duration-200 bg-red-500 rounded-full ring-2 ring-white">
            {displayCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div
          className="absolute right-0 mt-2 w-96 origin-top-right rounded-2xl bg-white shadow-xl ring-1 ring-black/5 animate-in fade-in-100 zoom-in-95"
          role="menu"
        >
          <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100">
            <h3 className="text-sm font-semibold text-slate-900">Thông báo</h3>
            {unreadCount > 0 && (
              <span className="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full">
                {unreadCount} chưa đọc
              </span>
            )}
          </div>

          <div className="max-h-[400px] overflow-y-auto">
            {isLoading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
              </div>
            ) : notifications.length === 0 ? (
              <div className="px-4 py-8 text-center">
                <Bell className="h-10 w-10 mx-auto text-slate-300" />
                <p className="mt-2 text-sm text-slate-500">Không có thông báo nào</p>
              </div>
            ) : (
              <ul className="divide-y divide-slate-100" role="list">
                {notifications.map((notification) => (
                  <li key={notification.notificationId} role="menuitem">
                    <button
                      onClick={() => handleNotificationClick(notification)}
                      className={`w-full px-4 py-3 text-left transition-colors hover:bg-slate-50 ${
                        !notification.readAt ? 'bg-blue-50/50' : ''
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${getTypeColor(notification.type)}`}>
                          {(() => { const Icon = getTypeIcon(notification.type); return <Icon className="h-4 w-4" />; })()}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className={`text-sm ${!notification.readAt ? 'font-semibold' : 'font-normal'} text-slate-900 truncate`}>
                            {notification.title}
                          </p>
                          <p className="mt-0.5 text-xs text-slate-500 line-clamp-1">
                            {notification.body}
                          </p>
                          <p className="mt-1.5 text-[10px] text-slate-400">
                            {formatDistanceToNow(new Date(notification.createdAt), { addSuffix: true, locale: vi })}
                          </p>
                        </div>
                        {!notification.readAt && (
                          <span className="flex h-2 w-2 shrink-0 mt-2 items-center justify-center bg-blue-500 rounded-full" />
                        )}
                      </div>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="px-4 py-3 border-t border-slate-100">
            <Link
              href="/notifications"
              onClick={handleShowAllClick}
              className="flex items-center justify-center gap-1.5 text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              Xem tất cả
              <ExternalLink className="h-3.5 w-3.5" />
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}