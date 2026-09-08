'use client';

import React from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import {
  Clock,
  CalendarDays,
  Briefcase,
  Users,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
  TrendingUp,
  FileCheck,
  ChevronRight,
  Sparkles,
  CreditCard
} from 'lucide-react';

export default function DashboardPage() {
  const { currentUser, roleLevel, isHR, isManager, isExecutive } = useAuth();
  const { attendances, leaveRequests, overtimeRecords } = useHRMData();

  const todayStr = '2026-09-04';
  const todayRecord = attendances.find(
    a => a.userId === currentUser?.userId && a.workDate === todayStr
  );

  // Pending counts
  const pendingLeaves = leaveRequests.filter(l => l.status === 'pending');
  const pendingOTs = overtimeRecords.filter(o => o.status === 'pending');

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Welcome Header */}
        <div className="rounded-3xl bg-gradient-to-r from-blue-700 via-blue-800 to-indigo-900 p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
          <div className="absolute -right-10 -bottom-10 h-64 w-64 rounded-full bg-blue-500/20 blur-2xl pointer-events-none" />
          <div className="relative z-10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full bg-white/10 backdrop-blur-md px-3 py-1 text-xs font-semibold text-blue-200 mb-2 border border-white/10">
                <Sparkles className="h-3.5 w-3.5 text-amber-300" />
                <span>Cổng Thông Tin Nhân Sự ACT</span>
              </div>
              <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
                Xin chào, {currentUser?.fullName || 'Nhân viên'}!
              </h1>
              <p className="mt-1 text-xs sm:text-sm text-blue-100 max-w-xl">
                {currentUser?.job} • Phòng {currentUser?.department} ({currentUser?.employeeCode})
              </p>
            </div>

            {/* Quick Actions in Header */}
            <div className="flex items-center gap-2.5">
              <Link
                href="/attendance"
                className="inline-flex items-center gap-2 rounded-xl bg-white/10 hover:bg-white/20 text-white px-4 py-2.5 text-xs sm:text-sm font-bold backdrop-blur-md border border-white/20 transition cursor-pointer"
              >
                <Clock className="h-4 w-4" />
                <span>Bảng Chấm Công</span>
              </Link>
              <Link
                href="/leave"
                className="inline-flex items-center gap-2 rounded-xl bg-white text-blue-900 hover:bg-blue-50 px-4 py-2.5 text-xs sm:text-sm font-bold shadow-md transition cursor-pointer"
              >
                <CalendarDays className="h-4 w-4 text-blue-600" />
                <span>Nộp Đơn Nghỉ Phép</span>
              </Link>
            </div>
          </div>
        </div>

        {/* Pending Approvals Notice for Managers & HR */}
        {(isManager || isHR || isExecutive) && (pendingLeaves.length > 0 || pendingOTs.length > 0) && (
          <div className="rounded-2xl bg-amber-50 p-4 border border-amber-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs">
            <div className="flex items-center gap-3">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-amber-100 text-amber-700 font-bold shrink-0">
                <FileCheck className="h-5 w-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-amber-900">
                  Bạn có yêu cầu đang chờ phê duyệt:
                </h4>
                <p className="text-[11px] text-amber-700">
                  {pendingLeaves.length} đơn xin nghỉ phép • {pendingOTs.length} đơn đăng ký làm thêm giờ (OT)
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Link
                href="/leave"
                className="rounded-lg bg-amber-600 hover:bg-amber-700 text-white px-3 py-1.5 text-xs font-bold transition"
              >
                Duyệt nghỉ phép
              </Link>
              <Link
                href="/overtime"
                className="rounded-lg bg-white border border-amber-300 text-amber-800 px-3 py-1.5 text-xs font-bold hover:bg-amber-100 transition"
              >
                Duyệt tăng ca
              </Link>
            </div>
          </div>
        )}

        {/* Primary Row: Attendance Status Overview & Month Stats */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Today Attendance Status (1 Col) */}
          <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-900">
                  <Clock className="h-4 w-4 text-blue-600" />
                  <span>Trạng thái công nhật hôm nay</span>
                </div>
                <span className="text-[11px] font-mono text-slate-500 bg-slate-100 px-2.5 py-0.5 rounded-full font-medium">
                  04/09/2026
                </span>
              </div>

              {/* Status Display */}
              <div className="rounded-2xl bg-slate-50 p-4 border border-slate-100 text-center mb-4">
                <div className="text-xs text-slate-500 mb-1">Ghi nhận công nhật</div>
                {todayRecord?.clockInTime ? (
                  <div>
                    <div className="inline-flex items-center gap-1.5 text-emerald-600 font-extrabold text-base">
                      <CheckCircle2 className="h-5 w-5" />
                      <span>{todayRecord.clockOutTime ? 'Đã hoàn thành ngày công' : 'Đang trong ca làm việc'}</span>
                    </div>
                    <div className="mt-3 grid grid-cols-2 gap-2 text-xs border-t border-slate-200/60 pt-3">
                      <div className="bg-white p-2.5 rounded-xl border border-slate-100">
                        <span className="text-slate-400 block text-[11px]">Giờ vào ca:</span>
                        <span className="font-mono font-bold text-slate-800 text-sm">{todayRecord.clockInTime}</span>
                      </div>
                      <div className="bg-white p-2.5 rounded-xl border border-slate-100">
                        <span className="text-slate-400 block text-[11px]">Giờ ra ca:</span>
                        <span className="font-mono font-bold text-slate-800 text-sm">
                          {todayRecord.clockOutTime || 'Chưa ghi nhận'}
                        </span>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div>
                    <div className="text-base font-bold text-amber-600">Chưa ghi nhận giờ vào</div>
                    <p className="mt-1 text-[11px] text-slate-400">
                      Hệ thống tự động đồng bộ khi nhân viên có mặt tại cơ quan.
                    </p>
                  </div>
                )}
              </div>

              {/* Shift Information */}
              <div className="space-y-2 text-xs text-slate-600 bg-slate-50/70 p-3.5 rounded-2xl border border-slate-100">
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Ca phân công:</span>
                  <span className="font-semibold text-slate-800">{currentUser?.shiftName || 'Ca hành chính chuẩn'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Khung giờ ca:</span>
                  <span className="font-mono font-medium text-slate-800">
                    {currentUser?.shiftStartTime || '08:30'} - {currentUser?.shiftEndTime || '17:30'}
                  </span>
                </div>
                <div className="flex justify-between items-center pt-1 border-t border-slate-200/60">
                  <span className="text-slate-400">Trạng thái chấm công:</span>
                  <span className="font-bold text-emerald-700">
                    {todayRecord ? 'Đã đồng bộ' : 'Chờ đồng bộ'}
                  </span>
                </div>
              </div>
            </div>

            <Link
              href="/attendance"
              className="mt-4 flex items-center justify-between rounded-xl bg-slate-50 hover:bg-blue-50 hover:text-blue-700 text-slate-700 p-2.5 text-xs font-bold transition border border-slate-200/60 group"
            >
              <span>Xem lịch sử chấm công chi tiết</span>
              <ArrowRight className="h-4 w-4 group-hover:translate-x-0.5 transition-transform" />
            </Link>
          </div>

          {/* Month Stats Overview (2 Cols) */}
          <div className="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4">
            {/* Stat 1: Working Days */}
            <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Công Tháng 09/2026</span>
                <span className="p-2 rounded-xl bg-blue-50 text-blue-600"><Clock className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black text-slate-900">4</span>
                  <span className="text-xs text-slate-400 font-medium">/ 22 ngày chuẩn</span>
                </div>
                <div className="mt-2 w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div className="bg-blue-600 h-2 rounded-full" style={{ width: '18%' }} />
                </div>
              </div>
              <p className="mt-3 text-[11px] text-slate-500">Chuẩn giờ làm: 8 giờ/ngày • Nghỉ T7 & CN</p>
            </div>

            {/* Stat 2: Annual Leave Balance */}
            <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Quỹ Phép Năm</span>
                <span className="p-2 rounded-xl bg-indigo-50 text-indigo-600"><CalendarDays className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black text-indigo-600">
                    {(currentUser?.annualLeaveDays || 12) - (currentUser?.usedLeaveDays || 0)}
                  </span>
                  <span className="text-xs text-slate-400 font-medium">/ {currentUser?.annualLeaveDays || 12} ngày phép</span>
                </div>
                <div className="mt-2 text-xs text-slate-600">Đã sử dụng: <strong>{currentUser?.usedLeaveDays || 0} ngày</strong></div>
              </div>
              <Link href="/leave" className="mt-3 text-[11px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                <span>Nộp đơn xin nghỉ phép</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>

            {/* Stat 3: Overtime Hours */}
            <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Tăng Ca (OT) Tháng Này</span>
                <span className="p-2 rounded-xl bg-orange-50 text-orange-600"><Briefcase className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black text-orange-600">4.0</span>
                  <span className="text-xs text-slate-400 font-medium">giờ đã phê duyệt</span>
                </div>
                <p className="mt-1 text-[11px] text-slate-500">Bao gồm 4.0h ngày Lễ Quốc Khánh 2/9 (Hệ số 3.0x)</p>
              </div>
              <Link href="/overtime" className="mt-3 text-[11px] font-bold text-orange-600 hover:text-orange-700 flex items-center gap-1">
                <span>Xem bản ghi tăng ca</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>

            {/* Stat 4: Payslip Shortcut */}
            <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Phiếu Lương Kỳ Gần Nhất</span>
                <span className="p-2 rounded-xl bg-emerald-50 text-emerald-600"><CreditCard className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="text-xs text-slate-500">Kỳ lương Tháng 08/2026:</div>
                <div className="text-2xl font-black text-emerald-600 mt-1">Đã chốt & chuyển khoản</div>
              </div>
              <Link href="/payroll" className="mt-3 text-[11px] font-bold text-emerald-600 hover:text-emerald-700 flex items-center gap-1">
                <span>Mở bảng lương chi tiết</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>
          </div>
        </div>

        {/* Quick Nav Row */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <Link
            href="/attendance"
            className="flex items-center gap-3 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:border-blue-300 hover:shadow-md transition group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 group-hover:scale-105 transition">
              <Clock className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xs font-bold text-slate-900">Bảng Chấm Công</div>
              <div className="text-[11px] text-slate-500">Xem lịch sử công nhật</div>
            </div>
          </Link>

          <Link
            href="/leave"
            className="flex items-center gap-3 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:border-indigo-300 hover:shadow-md transition group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 group-hover:scale-105 transition">
              <CalendarDays className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xs font-bold text-slate-900">Đơn Nghỉ Phép</div>
              <div className="text-[11px] text-slate-500">Nộp & theo dõi đơn</div>
            </div>
          </Link>

          <Link
            href="/overtime"
            className="flex items-center gap-3 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:border-orange-300 hover:shadow-md transition group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-50 text-orange-600 group-hover:scale-105 transition">
              <Briefcase className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xs font-bold text-slate-900">Làm Thêm Giờ</div>
              <div className="text-[11px] text-slate-500">Đăng ký & tính hệ số</div>
            </div>
          </Link>

          <Link
            href="/employees"
            className="flex items-center gap-3 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:border-purple-300 hover:shadow-md transition group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50 text-purple-600 group-hover:scale-105 transition">
              <Users className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xs font-bold text-slate-900">Danh Bạ Công Ty</div>
              <div className="text-[11px] text-slate-500">15 đồng nghiệp</div>
            </div>
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
