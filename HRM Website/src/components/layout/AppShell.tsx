'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import Navbar from './Navbar';
import Sidebar from './Sidebar';
import { useAuth } from '@/context/AuthContext';
import {
  LayoutDashboard,
  Clock,
  CalendarDays,
  Sparkles,
  User,
  Shield,
  CreditCard,
  Loader2
} from 'lucide-react';

export default function AppShell({ children }: { children: React.ReactNode }) {
  const [isMobileNavOpen, setIsMobileNavOpen] = useState(false);
  const pathname = usePathname();
  const { currentUser, isLoading } = useAuth();

  // ponytail: redirect only when token is missing (old check on !currentUser bounced to /login during profile fetch, causing redirect loops)
  useEffect(() => {
    if (isLoading) return;
    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    if (!token) {
      window.location.replace('/login');
    }
  }, [isLoading]);

  if (isLoading || !currentUser) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <div className="flex flex-col items-center gap-3 text-center">
          <div className="h-9 w-9 rounded-2xl bg-blue-600/10 flex items-center justify-center text-blue-600">
            <Loader2 className="h-5 w-5 animate-spin" />
          </div>
          <div>
            <p className="text-sm font-bold text-slate-800">ACT HRM</p>
            <p className="text-xs text-slate-400 mt-0.5">Đang kiểm tra quyền truy cập hệ thống...</p>
          </div>
        </div>
      </div>
    );
  }

  const bottomNavItems = [
    {
      name: 'Tổng quan',
      href: '/dashboard',
      icon: LayoutDashboard
    },
    {
      name: 'Chấm công',
      href: '/attendance',
      icon: Clock
    },
    {
      name: 'Nghỉ phép',
      href: '/leave',
      icon: CalendarDays
    },
    {
      name: 'Trợ lý AI',
      href: '/chat',
      icon: Sparkles,
      highlight: true
    },
    {
      name: 'Cá nhân',
      href: currentUser ? `/employees/${currentUser.userId}` : '/profile',
      icon: User
    }
  ];

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans selection:bg-blue-100 selection:text-blue-900">
      <Navbar onToggleMobileMenu={() => setIsMobileNavOpen(!isMobileNavOpen)} />
      
      <div className="flex flex-1">
        <Sidebar isOpen={isMobileNavOpen} onClose={() => setIsMobileNavOpen(false)} />
        
        {/* Main Content Area - padded at bottom on mobile to accommodate sticky bottom bar */}
        <main className="flex-1 p-3.5 sm:p-6 lg:p-8 max-w-7xl mx-auto w-full overflow-x-hidden pb-24 md:pb-8">
          {children}
        </main>
      </div>



      {/* Mobile Sticky Bottom Navigation Bar (Phone users native app feel) */}
      <nav 
        className="md:hidden fixed bottom-0 left-0 right-0 z-30 bg-white/95 backdrop-blur-md border-t border-slate-200/80 px-2 py-1 flex items-center justify-around shadow-lg safe-bottom"
        aria-label="Điều hướng di động nhanh"
      >
        {bottomNavItems.map(item => {
          const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all duration-150 min-w-[56px] ${
                isActive 
                  ? 'text-blue-600 font-semibold' 
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              <div className="relative">
                <Icon className={`h-5 w-5 ${isActive ? 'text-blue-600 stroke-[2.2]' : 'text-slate-500 stroke-[1.8]'}`} />
                {item.highlight && (
                  <span className="absolute -top-1 -right-1 flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-purple-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-purple-600"></span>
                  </span>
                )}
              </div>
              <span className={`text-[10px] mt-0.5 tracking-tight ${isActive ? 'font-bold text-blue-600' : 'font-medium'}`}>
                {item.name}
              </span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
