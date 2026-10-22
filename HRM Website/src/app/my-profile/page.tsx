'use client';

import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import EmployeeDetailPage from '@/app/employees/[id]/page';

// Hồ sơ cá nhân của chính mình — full-width, không sidebar.
export default function MyProfilePage() {
  const { currentUser } = useAuth();

  if (!currentUser) return null;

  return (
    <AppShell noSidebar>
      <EmployeeDetailPage userIdOverride={currentUser.userId} embedded />
    </AppShell>
  );
}
