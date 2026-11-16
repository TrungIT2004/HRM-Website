'use client';

import React from 'react';
import Navbar from './Navbar';
import Sidebar from './Sidebar';
import ToastContainer from '@/components/ui/ToastContainer';
import { NotificationProvider } from '@/context/NotificationContext';
import { useAuth } from '@/context/AuthContext';
import { useNotifications } from '@/context/NotificationContext';
import { useEffect } from 'react';

function AppShellInner({ children }: { children: React.ReactNode }) {
  const { currentUser } = useAuth();
  const { connect, disconnect } = useNotifications();

  // Feature flag for gradual rollout
  const notificationsEnabled = process.env.NEXT_PUBLIC_ENABLE_NOTIFICATIONS === 'true';

  // Connect/disconnect SSE on login/logout
  useEffect(() => {
    if (!notificationsEnabled) return;
    if (currentUser) {
      connect();
    } else {
      disconnect();
    }
  }, [currentUser, connect, disconnect, notificationsEnabled]);

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col">
      <Navbar />
      <div className="flex flex-1">
        <Sidebar />
        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto w-full overflow-x-hidden">
          {children}
        </main>
      </div>
      <ToastContainer />
    </div>
  );
}

export default function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <NotificationProvider>
      <AppShellInner>{children}</AppShellInner>
    </NotificationProvider>
  );
}
