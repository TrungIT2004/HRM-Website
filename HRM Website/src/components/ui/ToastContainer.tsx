'use client';

import React from 'react';
import { Bell, CheckCircle, XCircle, AlertCircle, Clock, ExternalLink } from 'lucide-react';
import { useNotifications } from '@/context/NotificationContext';
import { Notification } from '@/types';

const typeStyles: Record<string, { bg: string; border: string; iconColor: string; icon: React.ReactNode }> = {
  APPROVED: {
    bg: 'bg-emerald-50',
    border: 'border-emerald-200',
    iconColor: 'text-emerald-600',
    icon: <CheckCircle className="h-5 w-5" />
  },
  REJECTED: {
    bg: 'bg-red-50',
    border: 'border-red-200',
    iconColor: 'text-red-600',
    icon: <XCircle className="h-5 w-5" />
  },
  SUBMITTED: {
    bg: 'bg-blue-50',
    border: 'border-blue-200',
    iconColor: 'text-blue-600',
    icon: <AlertCircle className="h-5 w-5" />
  },
  CANCELLED: {
    bg: 'bg-amber-50',
    border: 'border-amber-200',
    iconColor: 'text-amber-600',
    icon: <Clock className="h-5 w-5" />
  },
  REVOKED: {
    bg: 'bg-purple-50',
    border: 'border-purple-200',
    iconColor: 'text-purple-600',
    icon: <AlertCircle className="h-5 w-5" />
  }
};

function ToastItem({
  toast,
  onRemove,
  onNavigate
}: {
  toast: { id: string; notification: Notification; visible: boolean };
  onRemove: (id: string) => void;
  onNavigate: (requestId: string, requestType: string) => void;
}) {
  const { notification } = toast;
  const action = notification.action;
  const style = typeStyles[action] || typeStyles.SUBMITTED;

  const handleClick = () => {
    onRemove(toast.id);
    onNavigate(notification.requestId, notification.requestType);
  };

  return (
    <div
      onClick={handleClick}
      className={`group flex items-start gap-3 p-4 rounded-xl border shadow-xl ${style.bg} ${style.border} animate-in slide-in-from-right-full duration-300 cursor-pointer hover:shadow-2xl transition-shadow`}
      role="alert"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          handleClick();
        }
      }}
    >
      <div className={`flex-shrink-0 ${style.iconColor}`}>
        {style.icon}
      </div>

      <div className="flex-1 min-w-0">
        <p className="font-semibold text-slate-900 text-sm">{notification.title}</p>
        <p className="text-slate-600 text-sm mt-0.5 line-clamp-2">{notification.message}</p>
        <p className="text-slate-400 text-xs mt-2 flex items-center gap-1">
          <Clock className="h-3 w-3" />
          {new Date(notification.createdAt).toLocaleString()}
        </p>
      </div>

      <button
        onClick={(e) => {
          e.stopPropagation();
          onRemove(toast.id);
        }}
        className="flex-shrink-0 text-slate-400 hover:text-slate-600 transition-colors p-1"
        aria-label="Dismiss notification"
      >
        <XCircle className="h-5 w-5" />
      </button>
    </div>
  );
}

export default function ToastContainer() {
  const { toasts, removeToast } = useNotifications();

  const handleNavigate = (requestId: string, requestType: string) => {
    // Navigate to appropriate page based on request type
    const routes: Record<string, string> = {
      LEAVE: `/leave/${requestId}`,
      OVERTIME: `/overtime/${requestId}`,
      RESIGNATION: `/resignation/${requestId}`,
      ASSET_REQUEST: `/asset-request/${requestId}`,
      GENERIC: '/notifications'
    };

    const route = routes[requestType] || '/notifications';
    window.location.href = route;
  };

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col-reverse gap-2 w-96 max-w-[calc(100vw-1rem)] pointer-events-none">
      {toasts.map((toast) => (
        <div key={toast.id} className="pointer-events-auto">
          <ToastItem
            toast={toast}
            onRemove={removeToast}
            onNavigate={handleNavigate}
          />
        </div>
      ))}
    </div>
  );
}