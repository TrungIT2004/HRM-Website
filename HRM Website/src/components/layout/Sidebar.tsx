'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import {
  LayoutDashboard,
  Clock,
  CalendarDays,
  Briefcase,
  Users,
  UserCheck,
  CreditCard,
  Building2,
  ExternalLink,
  ShieldAlert
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const { isHR, isExecutive, isManager, roleLevel, currentUser } = useAuth();

  const navItems = [
    {
      name: 'Tổng quan',
      href: '/dashboard',
      icon: LayoutDashboard,
      badge: undefined
    },
    {
      name: 'Chấm công & Giờ làm',
      href: '/attendance',
      icon: Clock,
      badge: undefined
    },
    {
      name: 'Quản lý Nghỉ phép',
      href: '/leave',
      icon: CalendarDays,
      badge: undefined
    },
    {
      name: 'Làm thêm giờ (OT)',
      href: '/overtime',
      icon: Briefcase,
      badge: undefined
    },
    {
      name: 'Danh bạ Nhân sự',
      href: '/employees',
      icon: Users,
      badge: '15'
    },
    {
      name: 'Hồ sơ Cá nhân',
      href: currentUser ? `/employees/${currentUser.userId}` : '/profile',
      icon: UserCheck,
      badge: undefined
    },
    {
      name: 'Tính lương & Thu nhập',
      href: '/payroll',
      icon: CreditCard,
      badge: isHR ? 'HR' : undefined
    }
  ];

  return (
    <aside className="w-64 flex-col border-r border-slate-200 bg-white shadow-xs hidden md:flex shrink-0 min-h-[calc(100vh-4rem)]">
      {/* Navigation Links */}
      <div className="flex-1 px-3 py-4 space-y-1">
        <div className="px-3 pb-2 text-[11px] font-bold tracking-wider text-slate-400 uppercase">
          Menu Điều hướng
        </div>

        {navItems.map(item => {
          const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-blue-50 text-blue-700 font-semibold shadow-xs'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`h-4 w-4 ${isActive ? 'text-blue-600' : 'text-slate-400'}`} />
                <span>{item.name}</span>
              </div>
              {item.badge && (
                <span className={`text-[10px] px-1.5 py-0.5 rounded-md font-semibold tracking-wide ${
                  item.badge === 'AI Face' 
                    ? 'bg-emerald-100 text-emerald-700' 
                    : item.badge === 'HR' 
                    ? 'bg-blue-100 text-blue-700' 
                    : 'bg-slate-100 text-slate-600'
                }`}>
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </div>

      {/* Role & Privileges Notice Box */}
      <div className="p-3 m-3 rounded-xl bg-slate-50 border border-slate-200/80">
        <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
          <Building2 className="h-4 w-4 text-blue-600" />
          <span>Công ty Cổ phần ACT</span>
        </div>
        <p className="mt-1 text-[11px] text-slate-500 leading-relaxed">
          {isExecutive && 'Quyền hạn: Ban Giám Đốc (Toàn quyền hệ thống & phê duyệt cấp cao).'}
          {!isExecutive && isHR && 'Quyền hạn: Quản trị Nhân sự (Quản lý hồ sơ, công & tính lương).'}
          {!isExecutive && !isHR && isManager && 'Quyền hạn: Trưởng phòng (Phê duyệt phép & tăng ca nội bộ).'}
          {!isExecutive && !isHR && !isManager && 'Quyền hạn: Nhân viên (Chấm công, xin phép, tra cứu hồ sơ).'}
        </p>

        <Link
          href="/"
          className="mt-2.5 flex items-center justify-between text-[11px] font-semibold text-blue-600 hover:text-blue-700 transition"
        >
          <span>Xem Landing Page SaaS</span>
          <ExternalLink className="h-3 w-3" />
        </Link>
      </div>
    </aside>
  );
}
