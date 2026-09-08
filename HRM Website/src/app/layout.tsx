import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/context/AuthContext';
import { HRMDataProvider } from '@/context/HRMDataContext';
import RoleSwitcher from '@/components/layout/RoleSwitcher';

export const metadata: Metadata = {
  title: 'ACT HRM - Nền tảng Quản trị Nhân sự & Chấm công AI',
  description: 'Hệ thống Quản lý Nhân sự, Chấm công nhận diện khuôn mặt AI, Nghỉ phép, Tăng ca và Tính lương tự động cho doanh nghiệp ACT.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;1,400&display=swap" rel="stylesheet" />
      </head>
      <body className="min-h-screen bg-slate-50 text-slate-900 font-sans antialiased">
        <AuthProvider>
          <HRMDataProvider>
            {children}
            <RoleSwitcher />
          </HRMDataProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
