import React from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { NotificationProvider } from '@/context/NotificationContext';
import { AuthProvider, useAuth } from '@/context/AuthContext';

const mockUser = {
  userId: 'user-1',
  employeeCode: 'EMP001',
  email: 'test@example.com',
  firstName: 'Test',
  lastName: 'User',
  fullName: 'Test User',
  department: 'Information Technology',
  job: 'Software Engineer',
  todayStatus: 'WORKING',
  annualLeaveDays: 12,
  usedLeaveDays: 0,
  shiftName: 'Ca 1',
  shiftStartTime: '08:30',
  shiftEndTime: '17:30',
  restDays: [6, 7],
};

function AuthProviderWrapper({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      {children}
    </AuthProvider>
  );
}

function NotificationProviderWrapper({ children }: { children: React.ReactNode }) {
  return (
    <NotificationProvider>
      {children}
    </NotificationProvider>
  );
}

function AllProviders({ children }: { children: React.ReactNode }) {
  return (
    <AuthProviderWrapper>
      <NotificationProviderWrapper>
        {children}
      </NotificationProviderWrapper>
    </AuthProviderWrapper>
  );
}

export function renderWithProviders(
  ui: React.ReactElement,
  options?: RenderOptions
) {
  return render(ui, {
    wrapper: AllProviders,
    ...options,
  });
}

// Re-export everything from testing-library
export * from '@testing-library/react';