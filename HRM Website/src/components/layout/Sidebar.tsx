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
  Shield,
  Settings,
  Sparkles,
  UserMinus,
  FileText,
  X
} from 'lucide-react';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export default function Sidebar({ isOpen = false, onClose }: SidebarProps) {
  const pathname = usePathname();
  const { isHR, isExecutive, isManager, isAdmin, isSysAdmin, currentUser, can } = useAuth();
  // khớp OrganizationService.checkOrganizationPermission: phòng HR hoặc grant ORG_MANAGE
  const canManageOrg =
    (currentUser?.department || '').toLowerCase() === 'human resources' || can('ORG_MANAGE');
  // khớp gate trang /admin (admin/page.tsx: canEnterAdmin)
  const canGrantPermissions = isSysAdmin || can('PERMISSION_GRANT');
  const canLockAccounts = isSysAdmin || can('ACCOUNT_LOCK');
  const canEnterAdmin = isAdmin || canGrantPermissions || canLockAccounts;

  // Mô tả quyền cho người được ủy quyền — chuỗi if bên dưới chỉ mô tả vai trò gốc
  const delegatedRoles = [
    canGrantPermissions && 'Cấp quyền cho người khác',
    canLockAccounts && 'Khoá/mở tài khoản & phiên',
    can('ORG_MANAGE') && 'Quản lý cơ cấu tổ chức'
  ].filter(Boolean);
  const delegatedRole = delegatedRoles.length
    ? `${delegatedRoles.join(', ')}${isManager ? ' (kèm phê duyệt cấp phòng)' : ''}`
    : null;

  const navItems = [
    {
      name: 'Tổng quan',
      href: '/dashboard',
      icon: LayoutDashboard
    },
    {
      name: 'Trợ lý AI',
      href: '/chat',
      icon: Sparkles
    },
    {
      name: 'Kho Tài liệu & Quy chế',
      href: '/documents',
      icon: FileText
    },
    {
      name: 'Chấm công & Giờ làm',
      href: '/attendance',
      icon: Clock
    },
    {
      name: 'Quản lý Nghỉ phép',
      href: '/leave',
      icon: CalendarDays
    },
    {
      name: 'Làm thêm giờ',
      href: '/overtime',
      icon: Briefcase
    },
    {
      name: 'Đơn Thôi việc',
      href: '/resignations',
      icon: UserMinus
    },
    {
      name: 'Danh bạ Nhân sự',
      href: '/employees',
      icon: Users
    },
    {
      name: 'Tính lương & Thu nhập',
      href: '/payroll',
      icon: CreditCard
    },
    ...(canManageOrg ? [{
      name: 'Cơ cấu Tổ chức',
      href: '/organization',
      icon: Building2
    }] : []),
    // Gate khớp đúng page /admin: ai vào được trang thì thấy link
    ...(canEnterAdmin ? [{
      name: isAdmin ? 'Quản trị Hệ thống' : 'Tài khoản & Phân quyền',
      href: '/admin',
      icon: Shield
    }] : []),
    // Luôn cuối menu: cài đặt là mục phụ, không theo nhóm nghiệp vụ nào
    {
      name: 'Cài đặt',
      href: '/settings',
      icon: Settings
    }
  ];

  const content = (
    <div className="flex flex-col h-full justify-between bg-white w-64 border-r border-slate-200">
      {/* Navigation Links */}
      <div className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <div className="flex items-center justify-between px-3 pb-2 text-[11px] font-bold tracking-wider text-slate-400 uppercase">
          <span>Menu Điều hướng</span>
          {onClose && (
            <button
              onClick={onClose}
              className="md:hidden p-1 text-slate-400 hover:text-slate-700 rounded-md transition"
              aria-label="Đóng menu"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>

        {navItems.map(item => {
          const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => onClose?.()}
              className={`flex items-center rounded-xl px-3.5 py-2.5 text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-blue-50 text-blue-700 font-semibold shadow-xs'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`h-4 w-4 shrink-0 ${isActive ? 'text-blue-600' : 'text-slate-400'}`} />
                <span className="truncate">{item.name}</span>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );

  return (
    <>
      {/* Desktop Persistent Sidebar */}
      <aside className="w-64 hidden md:flex shrink-0 min-h-[calc(100vh-4rem)] shadow-xs">
        {content}
      </aside>

      {/* Mobile Drawer (Slide-Over with Backdrop) */}
      {isOpen && (
        <div className="fixed inset-0 z-50 md:hidden flex">
          {/* Backdrop overlay */}
          <div 
            className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs transition-opacity animate-in fade-in" 
            onClick={onClose}
          />
          {/* Drawer content */}
          <div className="relative flex-1 flex flex-col max-w-xs w-full bg-white animate-in slide-in-from-left duration-200 shadow-2xl">
            {content}
          </div>
        </div>
      )}
    </>
  );
}
