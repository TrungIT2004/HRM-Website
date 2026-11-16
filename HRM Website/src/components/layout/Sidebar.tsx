'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import {
  Award,
  Clock,
  CalendarDays,
  Calendar,
  Briefcase,
  Users,
  CreditCard,
  Building2,
  Shield,
  KeyRound,
  Monitor,
  UserPlus,
  Sparkles,
  UserMinus,
  FileText,
  FileSpreadsheet,
  FileCheck,
  X,
  Plus,
  Inbox,
  PieChart,
  Network,
  Box,
  Package,
  Bell,
  History,
  Tags,
  type LucideIcon
} from 'lucide-react';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export default function Sidebar({ isOpen = false, onClose }: SidebarProps) {
  const pathname = usePathname();
  const { isAdmin, isSysAdmin, currentUser, can } = useAuth();

  const canManageOrg =
    (currentUser?.department || '').toLowerCase() === 'human resources' || can('ORG_MANAGE');
  const canGrantPermissions = isSysAdmin || can('PERMISSION_GRANT');
  const canLockAccounts = isSysAdmin || can('ACCOUNT_LOCK');
  // ponytail: MANAGE bao hàm VIEW — 1 check duy nhất cho cả module tài sản
  const canViewAssets = isSysAdmin || can('VIEW_ASSETS') || can('MANAGE_ASSETS');
  const canHandleTickets = isSysAdmin || can('IT_TICKET_HANDLE');

  const isOrgModule = pathname.startsWith('/organization');
  const isAttendanceModule = pathname.startsWith('/attendance') || pathname.startsWith('/leave') || pathname.startsWith('/overtime');
  const isManageModule = pathname.startsWith('/management');
  const isAssetPersonal = pathname === '/assets' || pathname.startsWith('/assets/requests');
  const isAssetManage = pathname.startsWith('/assets/management');
  const isTicketPersonal = pathname === '/tickets' || pathname === '/tickets/new';
  const isTicketManage = pathname.startsWith('/tickets/manage');
  // ponytail: 1 check duy nhat cho ca module danh gia — dung lai o home tile
  const canViewPerfManage = can('EVALUATION_VIEW_ALL') || can('EVALUATION_VIEW_DEPT')
    || can('EVALUATION_APPROVE') || can('EVALUATION_APPROVE_DEPT');
  const isPerfPersonal = pathname === '/performance-reviews' || pathname.startsWith('/performance-reviews/history');
  const isPerfManage = pathname.startsWith('/performance-reviews/management');
  const isRecruitModule = pathname.startsWith('/recruitment');
  const isSecurityModule = pathname.startsWith('/security');
  const isAdminModule = pathname.startsWith('/admin');

  // Specific Sub-navigation for Admin Module — mỗi tab là 1 route thật
  const adminNavItems = [
    ...(isAdmin ? [{
      name: 'Duyệt cấp tài khoản',
      href: '/admin/onboarding',
      icon: UserPlus
    }] : []),
    ...(isAdmin || canLockAccounts ? [{
      name: 'Tài khoản & Bảo mật',
      href: '/admin/accounts',
      icon: Shield
    }] : []),
    ...(canGrantPermissions ? [{
      name: 'Phân quyền',
      href: '/admin/permissions',
      icon: KeyRound
    }] : [])
  ];

  // Specific Sub-navigation for Organization Module — mỗi tab là 1 route thật
  const orgNavItems = [
    {
      name: 'Tổng quan & Báo cáo',
      href: '/organization/overview',
      icon: PieChart
    },
    {
      name: 'Sơ đồ cây tổ chức',
      href: '/organization/structure',
      icon: Network
    },
    ...(canManageOrg ? [{
      name: 'Phòng ban & Chức danh',
      href: '/organization/manage',
      icon: Building2
    }] : [])
  ];

  // Chấm công cá nhân — chỉ số liệu của chính mình
  const attendanceNavItems = [
    {
      name: 'Tổng quan của tôi',
      href: '/attendance/overview',
      icon: PieChart
    },
    {
      name: 'Chấm công hàng ngày',
      href: '/attendance/daily',
      icon: Clock
    },
    {
      name: 'Ca làm việc của tôi',
      href: '/attendance/schedule',
      icon: Calendar
    },
    {
      name: 'Đơn nghỉ phép',
      href: '/attendance/leave',
      icon: CalendarDays
    },
    {
      name: 'Làm thêm giờ (OT)',
      href: '/attendance/overtime',
      icon: Briefcase
    }
  ];

  // Quản lý chấm công — số liệu toàn công ty/phòng ban
  const manageNavItems = [
    {
      name: 'Tổng quan & Báo cáo',
      href: '/management/overview',
      icon: PieChart
    },
    {
      name: 'Chấm công',
      href: '/management/daily',
      icon: Clock
    },
    {
      name: 'Bảng tổng hợp công',
      href: '/management/summary',
      icon: FileSpreadsheet
    },
    {
      name: 'Quản lý đơn (Nghỉ/OT)',
      href: '/management/requests',
      icon: FileCheck
    }
  ];

  // Tài sản cá nhân — chỉ 2 mục của mình, không lẫn mục quản lý
  const assetPersonalNavItems = [
    {
      name: 'Tài sản của tôi',
      href: '/assets',
      icon: Box
    },
    {
      name: 'Đơn của tôi',
      href: '/assets/requests',
      icon: FileText
    }
  ];

  // Tài sản quản lý — chỉ 4 mục quản lý, không lẫn mục cá nhân
  const assetManageNavItems = canViewAssets ? [
    {
      name: 'Kho tài sản',
      href: '/assets/management/storage',
      icon: Package
    },
    {
      name: 'Duyệt đơn',
      href: '/assets/management/forms',
      icon: FileCheck
    },
    {
      name: 'Nhắc việc',
      href: '/assets/management/reminders',
      icon: Bell
    },
    {
      name: 'Vòng đời',
      href: '/assets/management/life-cycle',
      icon: History
    },
    {
      name: 'Danh mục',
      href: '/assets/management/categories',
      icon: Tags
    }
  ] : [];

  // IT ticket cá nhân — đơn của tôi + tạo đơn
  const ticketPersonalNavItems = [
    {
      name: 'Đơn của tôi',
      href: '/tickets',
      icon: FileText
    },
    {
      name: 'Tạo ticket',
      href: '/tickets/new',
      icon: Plus
    }
  ];

  // Xử lý IT — Tổng quan là trang đầu khi bấm module
  const ticketManageNavItems = canHandleTickets ? [
    {
      name: 'Tổng quan',
      href: '/tickets/manage/overview',
      icon: PieChart
    },
    {
      name: 'Hàng chờ xử lý',
      href: '/tickets/manage/queues',
      icon: Inbox
    },
    {
      name: 'Đã xử lý',
      href: '/tickets/manage/done',
      icon: History
    }
  ] : [];

  // Đánh giá hiệu suất cá nhân — 2 route thật: tự chấm + lịch sử
  const perfPersonalNavItems = [
    {
      name: 'Tự đánh giá',
      href: '/performance-reviews',
      icon: Award
    },
    {
      name: 'Lịch sử đánh giá',
      href: '/performance-reviews/history',
      icon: History
    }
  ];

  // QL Hiệu suất — 2 route thật: tổng quan + danh sách (gated như home tile)
  const perfManageNavItems = canViewPerfManage ? [
    {
      name: 'Tổng quan & Báo cáo',
      href: '/performance-reviews/management/overview',
      icon: PieChart
    },
    {
      name: 'Danh sách đánh giá',
      href: '/performance-reviews/management/records',
      icon: FileCheck
    }
  ] : [];

  // Tuyen dung — 2 route that: tao ho so + cho duyet
  const recruitNavItems = [
    {
      name: 'Tạo hồ sơ nhân sự',
      href: '/recruitment',
      icon: UserPlus
    },
    {
      name: 'Hồ sơ chờ duyệt',
      href: '/recruitment/pending',
      icon: Clock
    }
  ];

  // Specific Sub-navigation for Security Module — mỗi mục là 1 route thật
  const securityNavItems = [
    {
      name: 'Đổi mật khẩu',
      href: '/security/password',
      icon: KeyRound
    },
    {
      name: 'Quản lý phiên đăng nhập',
      href: '/security/sessions',
      icon: Monitor
    }
  ];

  // ponytail: mỗi app trên /home là 1 workspace độc lập — bấm app nào vào thẳng trang đó.
  // Sidebar không liệt kê toàn bộ menu cũ; trang đơn chỉ hiện đúng trang đó.
  const singleWorkspaces: Record<string, { name: string; icon: LucideIcon }> = {
    '/employees': { name: 'Danh bạ Nhân sự', icon: Users },
    '/payroll': { name: 'Tính lương & Thu nhập', icon: CreditCard },
    '/resignations': { name: 'Đơn Thôi việc', icon: UserMinus },
    '/documents': { name: 'Kho Tài liệu & Quy chế', icon: FileText },
    '/chat': { name: 'Trợ lý AI', icon: Sparkles }
  };
  // ponytail: /admin* đã có isAdminModule riêng nên không cần entry trong singleWorkspaces

  // ponytail: /employees/[id] chung workspace Danh bạ — sidebar trỏ về danh sách
  const singleKey = pathname.startsWith('/employees/') ? '/employees' : pathname;
  const single = !isOrgModule && !isAttendanceModule && !isManageModule && !isAssetPersonal && !isAssetManage && !isTicketPersonal && !isTicketManage && !isPerfPersonal && !isPerfManage && !isRecruitModule && !isSecurityModule && !isAdminModule ? singleWorkspaces[singleKey] : undefined;

  // ponytail: 2 workspace chấm công + admin bỏ tiêu đề module (trùng tên trang)
  const activeModuleTitle = isOrgModule
    ? 'Phân hệ Cơ Cấu'
    : isAttendanceModule || isManageModule || isAdminModule
      ? ''
      : isTicketPersonal
        ? 'Hỗ trợ IT'
        : isTicketManage
          ? 'Xử lý IT'
      : isPerfPersonal
        ? 'Đánh giá Hiệu suất'
        : isPerfManage
          ? 'QL Hiệu suất'
          : isRecruitModule
            ? 'Tuyển Dụng & Nhân Viên Mới'
            : isSecurityModule
              ? 'Cài Đặt'
              : single?.name ?? 'Không gian làm việc';

  const navItems: { name: string; href: string; icon: LucideIcon }[] = isOrgModule
    ? orgNavItems
    : isAttendanceModule
      ? attendanceNavItems
      : isManageModule
        ? manageNavItems
        : isAssetPersonal
          ? assetPersonalNavItems
          : isAssetManage
            ? assetManageNavItems
            : isTicketPersonal
              ? ticketPersonalNavItems
              : isTicketManage
                ? ticketManageNavItems
            : isPerfPersonal
              ? perfPersonalNavItems
              : isPerfManage
                ? perfManageNavItems
                : isRecruitModule
                  ? recruitNavItems
                  : isSecurityModule
                  ? securityNavItems
            : isAdminModule
              ? adminNavItems
              : single
                ? [{ ...single, href: singleKey }]
                : [];

  const content = (
    <div className="flex flex-col h-full justify-between bg-white w-64 border-r border-slate-200">
      {/* Navigation Links */}
      <div className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {/* Module Header — nút về /home đã có sẵn trên Navbar (9 chấm), không lặp lại ở đây */}
        <div className="mb-2">

          <div className="flex items-center justify-between px-3 pb-1 text-[11px] font-bold tracking-wider text-slate-400 uppercase">
            {activeModuleTitle && <span>{activeModuleTitle}</span>}
            {onClose && (
              <button
                onClick={onClose}
                className="md:hidden p-1 text-slate-400 hover:text-slate-700 rounded-md transition cursor-pointer"
                aria-label="Đóng menu"
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>

        {navItems.map(item => {
          const currentSearch = typeof window !== 'undefined' ? window.location.search : '';
          const currentFullUrl = `${pathname}${currentSearch}`;
          const isOverviewDefault = item.href.endsWith('tab=overview') && (!currentSearch || currentSearch === '?tab=overview') && pathname === item.href.split('?')[0];
          const isActive = item.href.includes('?')
            ? (currentFullUrl === item.href || isOverviewDefault)
            : pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={`${item.href}-${item.name}`}
              href={item.href}
              onClick={() => onClose?.()}
              className={`flex items-center rounded-xl px-3.5 py-2.5 text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-blue-50 text-blue-700 font-semibold shadow-xs'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon
                  className={`h-4 w-4 shrink-0 ${
                    isActive ? 'text-blue-600' : 'text-slate-400'
                  }`}
                />
                <span className="truncate">{item.name}</span>
              </div>
            </Link>
          );
        })}
      </div>

      {/* Footer Info */}
      <div className="p-3 border-t border-slate-100 text-[11px] text-slate-400 text-center">
        ACT HRM Enterprise v2.4
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
