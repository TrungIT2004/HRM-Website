'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import {
  LogOut,
  User as UserIcon,
  Clock,
  Menu,
  Sparkles,
  ShieldCheck,
  Building2,
  Settings as SettingsIcon
} from 'lucide-react';

import { attendanceService } from '@/services/attendanceService';

interface NavbarProps {
  onToggleMobileMenu?: () => void;
}

export default function Navbar({ onToggleMobileMenu }: NavbarProps) {
  const { currentUser, roleLevel, isAdmin, logout } = useAuth();
  const { attendances, isLoadingData } = useHRMData();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [isPunching, setIsPunching] = useState(false);

  const todayStr = new Date().toISOString().split('T')[0];
  const todayRecord = attendances.find(
    a => a.userId === currentUser?.userId && a.workDate === todayStr
  );
  // Không có bản ghi hôm nay = ngày nghỉ, vì cron chỉ tạo record cho ngày làm việc.
  // Chờ nạp xong mới kết luận để không báo nhầm lúc đang tải.
  const isDayOff = !isLoadingData && !todayRecord;

  const roleLabelMap: Record<string, { label: string; color: string }> = {
    EXECUTIVE: { label: 'Ban Giám Đốc', color: 'bg-purple-100 text-purple-700 border-purple-200' },
    HR: { label: 'Quản trị Nhân sự', color: 'bg-blue-100 text-blue-700 border-blue-200' },
    MANAGER: { label: 'Trưởng phòng', color: 'bg-amber-100 text-amber-700 border-amber-200' },
    STAFF: { label: 'Nhân viên', color: 'bg-emerald-100 text-emerald-700 border-emerald-200' }
  };

  const currentRoleBadge = isAdmin && roleLevel !== 'EXECUTIVE'
    ? { label: 'Quản trị Hệ thống', color: 'bg-indigo-100 text-indigo-700 border-indigo-200' }
    : roleLabelMap[roleLevel] || roleLabelMap.STAFF;

  const handleQuickPunch = async () => {
    if (!currentUser?.userId) return;
    setIsPunching(true);
    try {
      await attendanceService.checkAttendance(currentUser.userId);
    } catch {
      // ignore
    } finally {
      setIsPunching(false);
    }
  };

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between px-4 sm:px-6 glass-nav shadow-xs">
      {/* Left: Mobile Menu Toggle + Brand */}
      <div className="flex items-center gap-3">
        {/* Mobile Hamburger Button */}
        <button
          onClick={onToggleMobileMenu}
          className="md:hidden flex h-10 w-10 items-center justify-center rounded-xl text-slate-600 hover:bg-slate-100 hover:text-slate-900 transition cursor-pointer"
          aria-label="Mở menu điều hướng"
        >
          <Menu className="h-5 w-5" />
        </button>

        <Link href="/dashboard" className="flex items-center gap-2.5">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-600 font-bold text-white shadow-md shadow-blue-500/20 text-sm">
            ACT
          </div>
          <div className="flex flex-col">
            <span className="text-sm sm:text-base font-bold tracking-tight text-slate-900">ACT HRM</span>
            <span className="text-[10px] text-slate-400 font-medium sm:hidden">Hệ thống Nhân sự & Chấm công</span>
          </div>
        </Link>
      </div>

      {/* Right: Quick Punch + User Profile */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Today Punch Status Indicator */}
        <div className="hidden sm:flex items-center gap-1.5 text-xs text-slate-600 bg-slate-100/80 px-2.5 py-1.5 rounded-lg border border-slate-200/60">
          <Clock className="h-3.5 w-3.5 text-slate-500" />
          <span className="hidden md:inline">Hôm nay:</span>
          {isDayOff ? (
            <span className="text-slate-500 font-medium">Ngày nghỉ</span>
          ) : todayRecord?.clockInTime ? (
            <span className="font-semibold text-emerald-600">
              Vào {todayRecord.clockInTime.slice(0, 5)}
              {todayRecord.clockOutTime && ` • Ra ${todayRecord.clockOutTime.slice(0, 5)}`}
            </span>
          ) : (
            <span className="text-amber-600 font-medium">Chưa điểm danh</span>
          )}
        </div>

        {/* Quick Punch Button for Mobile / Header — ngày nghỉ thì không cho bấm. */}
        {!isDayOff && (
        <button
          onClick={handleQuickPunch}
          disabled={isPunching}
          title="Ghi giờ vào / ra"
          className="flex sm:hidden items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-semibold bg-blue-600 text-white shadow-xs hover:bg-blue-700 active:scale-95 transition"
        >
          <Clock className="h-3.5 w-3.5" />
          <span>{todayRecord?.clockInTime ? 'Ghi Giờ Ra' : 'Vào Ca'}</span>
        </button>
        )}

        {/* User Dropdown */}
        {currentUser && (
          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-2 rounded-xl p-1 hover:bg-slate-100 transition cursor-pointer"
            >
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-100 text-blue-800 font-bold text-sm ring-1 ring-blue-500/20">
                {currentUser.lastName?.[0] || currentUser.fullName?.[0] || 'U'}
              </div>
              <div className="hidden text-left md:block leading-tight">
                <div className="text-xs font-bold text-slate-900 max-w-[130px] truncate">{currentUser.fullName}</div>
                <div className="text-[11px] text-slate-500 max-w-[130px] truncate">{currentUser.job}</div>
              </div>
            </button>

            {showUserMenu && (
              <div className="absolute right-0 mt-2 w-72 rounded-2xl bg-white p-2.5 shadow-xl ring-1 ring-black/5 z-50 animate-in fade-in zoom-in-95 duration-150">
                <div className="px-3 py-2.5 border-b border-slate-100">
                  <p className="text-sm font-bold text-slate-900 truncate">{currentUser.fullName}</p>
                  <p className="text-xs text-slate-500 truncate">{currentUser.email}</p>
                  <div className="mt-2 flex items-center justify-between">
                    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold border ${currentRoleBadge.color}`}>
                      {currentRoleBadge.label}
                    </span>
                    <span className="text-[11px] font-mono text-slate-400">{currentUser.employeeCode}</span>
                  </div>
                </div>

                <div className="py-1.5 space-y-0.5">
                  <Link
                    href="/settings"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 rounded-xl transition"
                  >
                    <SettingsIcon className="h-4 w-4 text-slate-400" />
                    Cài đặt
                  </Link>
                  <Link
                    href="/attendance"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 rounded-xl transition"
                  >
                    <Clock className="h-4 w-4 text-slate-400" />
                    Lịch sử chấm công
                  </Link>
                  <Link
                    href="/chat"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 rounded-xl transition"
                  >
                    <Sparkles className="h-4 w-4 text-purple-500" />
                    Hỏi đáp Quy chế với AI
                  </Link>
                </div>

                <div className="pt-1.5 border-t border-slate-100">
                  <button
                    onClick={() => {
                      setShowUserMenu(false);
                      logout();
                    }}
                    className="flex w-full items-center gap-2.5 px-3 py-2 text-xs font-medium text-red-600 hover:bg-red-50 rounded-xl transition cursor-pointer"
                  >
                    <LogOut className="h-4 w-4" />
                    Đăng xuất khỏi hệ thống
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </header>
  );
}
