'use client';

import React, { ReactNode, useEffect } from 'react';
import { NotificationProvider } from '@/components/providers/NotificationProvider';
import { NotificationToasts } from '@/components/ui/NotificationToasts';
import { useDocumentTitleBadge } from '@/hooks/useDocumentTitleBadge';
import { useNotifications } from '@/components/providers/NotificationProvider';

function DocumentTitleUpdater() {
  const { unreadCount } = useNotifications();
  useDocumentTitleBadge(unreadCount);
  return null;
}

export function RootProviders({ children }: { children: ReactNode }) {
  return (
    <NotificationProvider>
      <DocumentTitleUpdater />
      {children}
      <NotificationToasts />
    </NotificationProvider>
  );
}