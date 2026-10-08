'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import {
  IdCard,
  Fingerprint,
  CircleDollarSign,
  Network,
  Users,
  UserPlus,
  UserMinus,
  FileText,
  Bot,
  ShieldCheck,
  Box,
  Award,
  Search,
  CheckCircle2,
  Lock,
  LogOut,
  Settings as SettingsIcon,
  Sparkles,
  ChevronDown,
  CalendarCheck,
  Wrench,
  LifeBuoy
} from 'lucide-react';

interface AppItem {
  id: string;
  name: string;
  category: 'nhansu' | 'chamcong' | 'vanphong' | 'hethong';
  icon: React.ComponentType<{ className?: string }>;
  gradient: string;
  href: string;
  isLocked?: boolean;
  badge?: string;
  requiredPermission?: string;
  // ponytail: phạm vi ảnh hưởng — 'manage' = đổi được dữ liệu người khác, còn lại mặc định 'personal'
  scope?: 'personal' | 'manage';
}

export default function HomePage() {
  const router = useRouter();
  const { currentUser, roleLevel, isAdmin, isSysAdmin, isHR, isManager, isExecutive, can, logout, isLoading } = useAuth();
  const [searchKeyword, setSearchKeyword] = useState<string>('');
  const [showUserMenu, setShowUserMenu] = useState<boolean>(false);
  const [toastMsg, setToastMsg] = useState<string>('');

  useEffect(() => {
    if (!isLoading && !currentUser) {
      const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
      if (!token) {
        router.replace('/login');
      }
    }
  }, [currentUser, isLoading, router]);

  const showNotification = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 3000);
  };

  const apps: AppItem[] = [
    {
      id: 'profile',
      name: 'Thông tin nhân sự',
      category: 'nhansu',
      icon: IdCard,
      gradient: 'from-blue-500 to-indigo-600',
      href: '/my-profile'
    },
    {
      id: 'attendance',
      name: 'Chấm công',
      category: 'chamcong',
      icon: Fingerprint,
      gradient: 'from-amber-500 to-orange-600',
      href: '/attendance/overview'
    },
    ...(isManager || isHR || isExecutive || can('ATTENDANCE_VIEW_ALL') || can('TIMESHEET_LOCK') || can('LEAVE_APPROVE') || can('OVERTIME_APPROVE') || can('ATTENDANCE_VIEW_DEPT') || can('LEAVE_VIEW_DEPT') || can('OVERTIME_VIEW_DEPT') || can('LEAVE_APPROVE_DEPT') || can('OVERTIME_APPROVE_DEPT') ? [{
      id: 'attendance-manager',
      name: 'Quản lý công & Duyệt đơn',
      category: 'chamcong' as const,
      scope: 'manage' as const,
      icon: CalendarCheck,
      gradient: 'from-amber-600 to-red-600',
      href: '/management/overview',
      badge: 'Quản lý'
    }] : []),
    {
      id: 'payroll',
      name: 'Tiền lương',
      category: 'chamcong',
      icon: CircleDollarSign,
      gradient: 'from-emerald-500 to-teal-600',
      href: '/payroll'
    },
    ...(can('ORG_MANAGE') ? [{
      id: 'organization',
      name: 'Cơ cấu tổ chức',
      category: 'nhansu' as const,
      scope: 'manage' as const,
      icon: Network,
      gradient: 'from-sky-500 to-blue-600',
      href: '/organization/overview'
    }] : []),
    {
      id: 'employees',
      name: 'Danh bạ nhân sự',
      category: 'nhansu',
      icon: Users,
      gradient: 'from-purple-500 to-indigo-600',
      href: '/employees'
    },
    ...((isHR || isAdmin || can('EMPLOYEE_EDIT')) ? [{
      id: 'onboarding',
      name: 'Nhân viên mới & Tuyển dụng',
      category: 'nhansu' as const,
      scope: 'manage' as const,
      icon: UserPlus,
      gradient: 'from-violet-600 to-purple-700',
      href: '/recruitment',
      badge: isHR || isAdmin ? 'HR / Admin' : undefined
    }] : []),
    {
      id: 'resignation',
      name: 'Đơn thôi việc',
      category: 'nhansu',
      icon: UserMinus,
      gradient: 'from-rose-500 to-pink-600',
      href: '/resignations'
    },
    {
      id: 'documents',
      name: 'Kho tài liệu & Quy chế',
      category: 'vanphong',
      icon: FileText,
      gradient: 'from-blue-600 to-cyan-600',
      href: '/documents'
    },
    {
      id: 'chat',
      name: 'Trợ lý AI',
      category: 'vanphong',
      icon: Bot,
      gradient: 'from-fuchsia-600 to-pink-600',
      href: '/chat'
    },
    ...((isSysAdmin || can('PERMISSION_GRANT')) ? [{
      id: 'admin',
      name: 'Quản trị hệ thống',
      category: 'hethong' as const,
      scope: 'manage' as const,
      icon: ShieldCheck,
      gradient: 'from-slate-700 to-slate-900',
      href: '/admin',
      badge: 'Bảo mật'
    }] : []),
    {
      id: 'security',
      name: 'Cài đặt',
      category: 'hethong',
      icon: SettingsIcon,
      gradient: 'from-slate-400 to-slate-600',
      href: '/security/password'
    },
    {
      id: 'assets',
      name: 'Tài sản của tôi',
      category: 'vanphong',
      icon: Box,
      gradient: 'from-emerald-600 to-teal-700',
      href: '/assets'
    },
    ...((can('VIEW_ASSETS') || can('MANAGE_ASSETS')) ? [{
      id: 'assets-manager',
      name: 'Quản lý tài sản',
      category: 'vanphong' as const,
      scope: 'manage' as const,
      icon: Box,
      gradient: 'from-teal-700 to-cyan-800',
      href: '/assets/management/storage',
      badge: 'Quản lý'
    }] : []),
    {
      id: 'tickets',
      name: 'Hỗ trợ IT',
      category: 'vanphong',
      icon: LifeBuoy,
      gradient: 'from-cyan-500 to-blue-600',
      href: '/tickets'
    },
    ...((isSysAdmin || can('IT_TICKET_HANDLE')) ? [{
      id: 'tickets-manager',
      name: 'Xử lý vấn đề IT',
      category: 'vanphong' as const,
      scope: 'manage' as const,
      icon: Wrench,
      gradient: 'from-blue-700 to-indigo-800',
      href: '/tickets/manage/overview',
      badge: 'Quản lý'
    }] : []),
    {
      id: 'evaluation',
      name: 'Đánh giá hiệu suất',
      category: 'nhansu',
      icon: Award,
      gradient: 'from-amber-500 to-yellow-600',
      href: '/performance-reviews'
    },
    ...((can('EVALUATION_VIEW_ALL') || can('EVALUATION_VIEW_DEPT') || can('EVALUATION_APPROVE') || can('EVALUATION_APPROVE_DEPT')) ? [{
      id: 'evaluation-manager',
      name: 'QL Hiệu suất',
      category: 'nhansu' as const,
      scope: 'manage' as const,
      icon: Award,
      gradient: 'from-amber-600 to-orange-700',
      href: '/performance-reviews/management/overview',
      badge: 'Quản lý'
    }] : []),
  ];

  const filteredApps = apps.filter(app => {
    const matchSearch = app.name.toLowerCase().includes(searchKeyword.toLowerCase().trim());
    return matchSearch;
  });

  const handleAppClick = (app: AppItem, e: React.MouseEvent) => {
    if (app.isLocked) {
      e.preventDefault();
      showNotification(`Phân hệ "${app.name}" đang được xây dựng và sẽ ra mắt trong giai đoạn tiếp theo.`);
    }
  };

  // ponytail: gom nhóm Cá nhân / Quản lý khi không tìm kiếm (có tìm kiếm thì list phẳng)
  const isGrouped = !searchKeyword.trim();
  const personalApps = filteredApps.filter(app => app.scope !== 'manage');
  const manageApps = filteredApps.filter(app => app.scope === 'manage');

  const renderTile = (app: AppItem) => {
    const Icon = app.icon;
    return (
      <Link
        key={app.id}
        href={app.href}
        onClick={e => handleAppClick(app, e)}
        className={`group flex flex-col items-center text-center transition-all duration-200 ${
          app.isLocked ? 'opacity-70 hover:opacity-85' : 'hover:-translate-y-1.5'
        }`}
      >
        {/* Squircle Tile with Gradient and Shadow */}
        <div className="relative mb-2.5">
          <div
            className={`w-16 h-16 sm:w-20 sm:h-20 rounded-2xl sm:rounded-3xl bg-linear-to-br ${app.gradient} flex items-center justify-center text-white shadow-xl shadow-black/40 ring-1 ring-white/25 group-hover:shadow-2xl group-hover:ring-white/40 transition-all duration-200 group-hover:scale-105`}
          >
            <Icon className="w-8 h-8 sm:w-9 sm:h-9 stroke-[2] drop-shadow-md" />
          </div>

          {/* Status Indicator Badge (Green checkmark or Lock) */}
          <div className="absolute -bottom-1 -right-1 flex items-center justify-center">
            {app.isLocked ? (
              <div className="h-5 w-5 sm:h-6 sm:w-6 rounded-full bg-slate-800/90 text-slate-300 flex items-center justify-center ring-2 ring-black/40 shadow-xs">
                <Lock className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
              </div>
            ) : (
              <div className="h-5 w-5 sm:h-6 sm:w-6 rounded-full bg-emerald-500 text-white flex items-center justify-center ring-2 ring-black/40 shadow-xs">
                <CheckCircle2 className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
              </div>
            )}
          </div>
        </div>

        {/* App Label with Drop Shadow */}
        <span className="text-xs sm:text-sm font-semibold text-white tracking-tight drop-shadow-md text-center max-w-[110px] leading-tight group-hover:text-blue-200 transition">
          {app.name}
        </span>
      </Link>
    );
  };

  const renderGrid = (apps: AppItem[]) => (
    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-6 sm:gap-8 justify-items-center">
      {apps.map(renderTile)}
    </div>
  );

  if (isLoading || !currentUser) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="flex flex-col items-center gap-3 text-center">
          <div className="h-10 w-10 animate-spin rounded-full border-3 border-blue-500 border-t-transparent" />
          <p className="text-xs text-slate-300 font-medium">Đang tải không gian làm việc...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen relative flex flex-col justify-between font-sans selection:bg-blue-600 selection:text-white bg-slate-950 overflow-x-hidden">
      {/* Background Image: Atmospheric Landscape with Blur Overlay */}
      <div 
        className="fixed inset-0 -z-10 bg-cover bg-center transition-all duration-700 scale-105"
        style={{
          backgroundImage: `url('https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=2400&q=80')`,
          filter: 'brightness(0.72) contrast(1.05)'
        }}
      />
      <div className="fixed inset-0 -z-10 bg-linear-to-b from-black/40 via-transparent to-black/60 pointer-events-none" />

      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-slate-900/90 text-white border border-slate-700/80 px-4 py-2.5 rounded-2xl shadow-2xl backdrop-blur-md text-xs font-medium flex items-center gap-2 animate-in fade-in slide-in-from-top-4 duration-200">
          <Sparkles className="w-4 h-4 text-amber-400 shrink-0" />
          <span>{toastMsg}</span>
        </div>
      )}

      {/* Top Header / Navigation Bar */}
      <header className="sticky top-0 z-40 px-4 sm:px-8 py-3.5 backdrop-blur-md bg-black/25 border-b border-white/10 flex items-center justify-between gap-4">
        {/* Brand / Logo */}
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 rounded-xl bg-linear-to-tr from-blue-600 to-indigo-500 flex items-center justify-center font-extrabold text-white text-sm shadow-lg shadow-blue-500/25 ring-1 ring-white/20">
            ACT
          </div>
          <div className="hidden sm:flex flex-col">
            <span className="text-sm font-black tracking-tight text-white drop-shadow-xs">ACT HRM PORTAL</span>
            <span className="text-[10px] text-slate-300 font-medium tracking-wider uppercase">Cổng Dịch vụ Nhân sự Doanh nghiệp</span>
          </div>
        </div>

        {/* Right Area: Search + User Menu */}
        <div className="flex items-center gap-3">
          {/* Quick Search */}
          <div className="relative w-36 sm:w-56">
            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-white/50" />
            <input
              type="text"
              value={searchKeyword}
              onChange={e => setSearchKeyword(e.target.value)}
              placeholder="Tìm ứng dụng..."
              className="w-full bg-white/15 hover:bg-white/20 focus:bg-white/25 text-white placeholder-white/50 text-xs rounded-xl pl-8 pr-3 py-1.5 border border-white/10 focus:outline-hidden focus:ring-1 focus:ring-blue-400 transition"
            />
          </div>

          {/* User Profile Dropdown */}
          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-2 p-1 rounded-xl hover:bg-white/15 transition cursor-pointer"
            >
              <div className="h-8 w-8 rounded-xl bg-blue-500 text-white font-bold text-xs flex items-center justify-center ring-2 ring-white/30 shadow-md">
                {currentUser.lastName?.[0] || currentUser.fullName?.[0] || 'U'}
              </div>
              <div className="hidden lg:block text-left text-xs leading-tight">
                <p className="font-bold text-white truncate max-w-[120px]">{currentUser.fullName}</p>
                <p className="text-[10px] text-slate-300 truncate max-w-[120px]">{currentUser.job || 'Nhân viên'}</p>
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-white/60 hidden sm:block" />
            </button>

            {showUserMenu && (
              <div className="absolute right-0 mt-2 w-64 rounded-2xl bg-slate-900/95 border border-white/15 text-white p-2 shadow-2xl backdrop-blur-xl z-50 animate-in fade-in duration-150">
                <div className="p-3 border-b border-white/10">
                  <p className="text-xs font-bold text-white truncate">{currentUser.fullName}</p>
                  <p className="text-[11px] text-slate-400 truncate">{currentUser.email}</p>
                  <span className="inline-block mt-1.5 px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-600/30 text-blue-300 border border-blue-400/30">
                    {currentUser.department || 'Nhân viên'}
                  </span>
                </div>
                <div className="py-1 space-y-0.5 text-xs">
                  <Link
                    href="/my-profile"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 rounded-xl text-slate-300 hover:text-white hover:bg-white/10 transition"
                  >
                    <IdCard className="w-4 h-4 text-blue-400" />
                    <span>Hồ sơ cá nhân</span>
                  </Link>
                  <Link
                    href="/admin"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 rounded-xl text-slate-300 hover:text-white hover:bg-white/10 transition"
                  >
                    <SettingsIcon className="w-4 h-4 text-slate-400" />
                    <span>Cài đặt hệ thống</span>
                  </Link>
                </div>
                <div className="pt-1 border-t border-white/10">
                  <button
                    onClick={() => {
                      setShowUserMenu(false);
                      logout();
                    }}
                    className="flex w-full items-center gap-2.5 px-3 py-2 rounded-xl text-red-400 hover:text-red-300 hover:bg-red-500/10 transition text-xs font-medium cursor-pointer"
                  >
                    <LogOut className="w-4 h-4" />
                    <span>Đăng xuất</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Main Apps Grid Container */}
      <main className="flex-1 max-w-6xl mx-auto w-full px-4 sm:px-8 py-10 sm:py-16 flex flex-col justify-center">
        {/* App Icons Grid — gom nhóm Cá nhân / Quản lý khi xem tất cả */}
        {isGrouped ? (
          <div className="space-y-10">
            <section>
              <h2 className="text-xs font-bold uppercase tracking-widest text-white/50 mb-5 text-center">Cá nhân</h2>
              {renderGrid(personalApps)}
            </section>
            {manageApps.length > 0 && (
              <section>
                <h2 className="text-xs font-bold uppercase tracking-widest text-white/50 mb-5 text-center">Quản lý</h2>
                {renderGrid(manageApps)}
              </section>
            )}
          </div>
        ) : (
          renderGrid(filteredApps)
        )}

        {filteredApps.length === 0 && (
          <div className="text-center py-16">
            <p className="text-sm text-slate-300 font-medium">Không tìm thấy ứng dụng nào phù hợp với từ khóa "{searchKeyword}".</p>
            <button
              onClick={() => {
                setSearchKeyword('');
              }}
              className="mt-3 px-4 py-1.5 rounded-xl bg-white/20 hover:bg-white/30 text-white text-xs font-bold transition cursor-pointer"
            >
              Xem tất cả ứng dụng
            </button>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="px-4 py-4 text-center text-[11px] text-white/50 backdrop-blur-xs bg-black/20 border-t border-white/5">
        <span>© 2026 ACT Corporation • Nền tảng Quản trị Doanh nghiệp & Nhân sự Thông minh ACT HRM</span>
      </footer>
    </div>
  );
}
