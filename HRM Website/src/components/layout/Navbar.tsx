'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { 
  Bell, 
  Search, 
  LogOut, 
  User as UserIcon, 
  ShieldCheck, 
  Sparkles,
  CheckCircle2,
  Clock
} from 'lucide-react';

export default function Navbar() {
  const { currentUser, roleLevel, logout } = useAuth();
  const { attendances } = useHRMData();
  const [showUserMenu, setShowUserMenu] = useState(false);

  const todayStr = '2026-09-04';
  const todayRecord = attendances.find(
    a => a.userId === currentUser?.userId && a.workDate === todayStr
  );

  const roleLabelMap: Record<string, { label: string; color: string }> = {
    EXECUTIVE: { label: 'Ban Giám Đốc', color: 'bg-purple-100 text-purple-700 border-purple-200' },
    HR: { label: 'Quản trị Nhân sự', color: 'bg-blue-100 text-blue-700 border-blue-200' },
    MANAGER: { label: 'Trưởng phòng', color: 'bg-amber-100 text-amber-700 border-amber-200' },
    STAFF: { label: 'Nhân viên', color: 'bg-emerald-100 text-emerald-700 border-emerald-200' }
  };

  const currentRoleBadge = roleLabelMap[roleLevel] || roleLabelMap.STAFF;

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between px-6 glass-nav shadow-xs">
      {/* Left: Brand / System Status */}
      <div className="flex items-center gap-4">
        <Link href="/dashboard" className="flex items-center gap-2.5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-600 font-bold text-white shadow-md shadow-blue-500/20">
            ACT
          </div>
          <div className="hidden sm:block">
            <span className="text-base font-bold tracking-tight text-slate-900">ACT HRM</span>
            <span className="ml-1.5 text-xs text-slate-500 font-medium">Enterprise</span>
          </div>
        </Link>

        {/* Camera Sync Status Badge */}
        <div className="hidden md:flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-1 border border-emerald-200 text-xs text-emerald-700 font-medium">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span>Thiết bị chấm công: Đang kết nối</span>
        </div>
      </div>

      {/* Right: Quick Attendance + User Profile */}
      <div className="flex items-center gap-3">

        {/* Today Punch Status Indicator */}
        <div className="hidden lg:flex items-center gap-1.5 text-xs text-slate-600 bg-slate-100 px-2.5 py-1 rounded-md">
          <Clock className="h-3.5 w-3.5 text-slate-500" />
          <span>Hôm nay:</span>
          {todayRecord?.clockInTime ? (
            <span className="font-semibold text-emerald-600">
              Vào {todayRecord.clockInTime.slice(0, 5)}
              {todayRecord.clockOutTime && ` • Ra ${todayRecord.clockOutTime.slice(0, 5)}`}
            </span>
          ) : (
            <span className="text-amber-600 font-medium">Chưa điểm danh</span>
          )}
        </div>

        {/* User Dropdown */}
        {currentUser && (
          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-2.5 rounded-lg p-1.5 hover:bg-slate-100 transition cursor-pointer"
            >
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-200 font-bold text-sm text-slate-700 ring-2 ring-blue-500/20">
                {currentUser.lastName?.[0] || currentUser.fullName?.[0]}
              </div>
              <div className="hidden text-left sm:block leading-tight">
                <div className="text-xs font-bold text-slate-900 line-clamp-1">{currentUser.fullName}</div>
                <div className="text-[11px] text-slate-500 line-clamp-1">{currentUser.job}</div>
              </div>
            </button>

            {showUserMenu && (
              <div className="absolute right-0 mt-2 w-64 rounded-xl bg-white p-2 shadow-xl ring-1 ring-black/5 z-50 animate-in fade-in zoom-in-95 duration-150">
                <div className="px-3 py-2.5 border-b border-slate-100">
                  <p className="text-sm font-bold text-slate-900">{currentUser.fullName}</p>
                  <p className="text-xs text-slate-500 truncate">{currentUser.email}</p>
                  <div className="mt-2 flex items-center justify-between">
                    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold border ${currentRoleBadge.color}`}>
                      {currentRoleBadge.label}
                    </span>
                    <span className="text-[11px] font-mono text-slate-400">{currentUser.employeeCode}</span>
                  </div>
                </div>

                <div className="py-1">
                  <Link
                    href={`/employees/${currentUser.userId}`}
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 rounded-lg transition"
                  >
                    <UserIcon className="h-4 w-4 text-slate-400" />
                    Hồ sơ chi tiết của tôi
                  </Link>
                  <Link
                    href="/attendance"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 rounded-lg transition"
                  >
                    <Clock className="h-4 w-4 text-slate-400" />
                    Lịch sử chấm công
                  </Link>
                </div>

                <div className="pt-1 border-t border-slate-100">
                  <button
                    onClick={() => {
                      setShowUserMenu(false);
                      logout();
                    }}
                    className="flex w-full items-center gap-2.5 px-3 py-2 text-xs font-medium text-red-600 hover:bg-red-50 rounded-lg transition cursor-pointer"
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
