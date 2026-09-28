'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { dashboardService, DashboardSummaryResponse } from '@/services/dashboardService';
import { toLocalISO } from '@/utils/dateRange';
import {
  Clock,
  CalendarDays,
  Briefcase,
  Users,
  UserMinus,
  ArrowRight,
  TrendingUp,
  FileCheck,
  CreditCard,
  Bot
} from 'lucide-react';

// Backend trả về đúng tên enum AttendanceStatus; chỉ dịch các ca hay gặp,
// ca lạ thì hiện nguyên code để không giấu trạng thái.
const STATUS_LABEL: Record<string, string> = {
  WORKING: 'Đang làm việc',
  SUFFICIENT: 'Đủ giờ',
  LATE: 'Đi muộn',
  EARLY: 'Về sớm',
  LATE_AND_EARLY: 'Đi muộn & về sớm',
  NOT_CHECKED: 'Chưa quẹt mặt',
  NOT_CHECKED_IN: 'Ngày nghỉ',
  MISSING: 'Thiếu chấm công',
  UNEXCUSED_ABSENCE: 'Vắng mặt không phép',
  PAID_LEAVE: 'Nghỉ phép có lương',
  UNPAID_LEAVE: 'Nghỉ phép không lương',
  HOLIDAY: 'Ngày lễ',
  BUSINESS_TRIP: 'Đi công tác',
  ADJUSTED: 'Đã điều chỉnh'
};
const BAD_STATUS = ['LATE', 'EARLY', 'LATE_AND_EARLY', 'MISSING', 'UNEXCUSED_ABSENCE', 'NOT_CHECKED'];

export default function DashboardPage() {
  const { currentUser, isHR, isManager, isExecutive, isAccounting, can } = useAuth();
  const {
    attendances,
    leaveRequests,
    overtimeRecords
  } = useHRMData();

  const [summaryData, setSummaryData] = useState<DashboardSummaryResponse | null>(null);
  const [isSummaryLoading, setIsSummaryLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    setIsSummaryLoading(true);
    dashboardService.getSummary()
      .then(data => {
        if (isMounted && data) {
          setSummaryData(data);
        }
      })
      .catch(() => {})
      .finally(() => {
        if (isMounted) setIsSummaryLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [currentUser]);

  // toISOString là UTC → sau 17:00 giờ VN ra ngày hôm trước, mất luôn bản ghi chấm công hôm nay.
  const todayStr = toLocalISO(new Date());
  const todayRecord = attendances.find(
    a => a.userId === currentUser?.userId && a.workDate === todayStr
  );

  // Pending counts from API
  const pendingLeavesCount = summaryData?.management?.pendingLeavesCount ?? leaveRequests.filter(l => l.status === 'pending').length;
  const pendingOTsCount = summaryData?.management?.pendingOvertimesCount ?? overtimeRecords.filter(o => o.status === 'pending').length;

  const clockIn = todayRecord?.clockInTime || summaryData?.clockInTime;
  const clockOut = todayRecord?.clockOutTime || summaryData?.clockOutTime;

  // Backend đã phân biệt sẵn: "NOT_CHECKED_IN" = hôm nay KHÔNG có bản ghi chấm công,
  // tức là ngày nghỉ (cron chỉ tạo record cho ngày làm việc). Còn "NOT_CHECKED"
  // là có record nhưng chưa quẹt mặt — vẫn phải bắt quẹt.
  const isDayOff = summaryData?.todayStatus === 'NOT_CHECKED_IN';

  const workedDays = summaryData?.monthSummary?.totalWorkDays ?? 0;
  const standardDays = summaryData?.monthSummary?.standardWorkDays ?? 22;
  const remainingLeaves = summaryData?.monthSummary?.remainingLeaveDays ?? ((currentUser?.annualLeaveDays || 12) - (currentUser?.usedLeaveDays || 0));
  const otHours = summaryData?.monthSummary?.totalOtHours ?? 0;
  const lateDays = summaryData?.monthSummary?.lateDays ?? 0;

  // Hôm nay lấy thẳng từ summary endpoint (backend đã join bảng attendances) —
  // không tự tính giờ để khỏi lệch với bảng chấm công chính thức.
  const todayStatus = todayRecord?.status || summaryData?.todayStatus || 'NOT_CHECKED';
  const statusText = STATUS_LABEL[todayStatus] || todayStatus;

  // Ô lối tắt theo vai trò. Khớp gate từng trang đích:
  //  /leave, /overtime  — isManager || isHR || isExecutive (pending banner ở trên)
  //  /resignations      — resignations/page.tsx:76 (isManager || isHR || isExecutive || can('RESIGN_APPROVE'))
  //  /attendance        — bảng tổng hợp công toàn công ty, HR đọc được company scope
  //  /payroll           — payroll/page.tsx:156 nút "Chạy Tính Lương"
  // ?tab= mở thẳng tab (xem utils/initialTab). Ô lương không có tab — nút bấm được.
  const roleTasks = [
    ...((isManager || isHR || isExecutive) ? [{
      name: 'Duyệt nghỉ phép', desc: 'Xét đơn nghỉ phép chờ duyệt',
      href: '/leave?tab=approvals', icon: CalendarDays, iconBg: 'bg-indigo-50', iconFg: 'text-indigo-600', count: pendingLeavesCount
    }] : []),
    ...((isManager || isHR || isExecutive) ? [{
      name: 'Duyệt tăng ca', desc: 'Xét đơn làm thêm giờ',
      href: '/overtime?tab=approvals', icon: Briefcase, iconBg: 'bg-orange-50', iconFg: 'text-orange-600', count: pendingOTsCount
    }] : []),
    ...((isManager || isHR || isExecutive || can('RESIGN_APPROVE')) ? [{
      name: 'Duyệt nghỉ việc', desc: 'Xét đơn từ chức & bàn giao',
      href: '/resignations?tab=approvals', icon: UserMinus, iconBg: 'bg-slate-100', iconFg: 'text-slate-600', count: 0
    }] : []),
    ...(isHR ? [{
      name: 'Tổng hợp công công ty', desc: 'Chốt timesheet toàn công ty',
      href: '/attendance?tab=summary', icon: Users, iconBg: 'bg-blue-50', iconFg: 'text-blue-600', count: 0
    }] : []),
    ...(isAccounting ? [{
      name: 'Tính lương & Thu nhập', desc: 'Chạy tính lương theo tháng',
      href: '/payroll', icon: CreditCard, iconBg: 'bg-emerald-50', iconFg: 'text-emerald-600', count: 0
    }] : [])
  ];

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Pending Approvals Notice (Managers, HR, Executive) */}
        {(isManager || isHR || isExecutive) && (pendingLeavesCount > 0 || pendingOTsCount > 0) && (
          <div className="rounded-2xl bg-amber-50/90 p-4 border border-amber-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-100 text-amber-700 font-bold shrink-0">
                <FileCheck className="h-5 w-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-amber-900">
                  Bạn có yêu cầu của nhân viên đang chờ xét duyệt:
                </h4>
                <p className="text-[11px] text-amber-700 mt-0.5">
                  <strong>{pendingLeavesCount}</strong> đơn nghỉ phép • <strong>{pendingOTsCount}</strong> đơn làm thêm giờ (OT)
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <Link
                href="/leave?tab=approvals"
                className="rounded-xl bg-amber-600 hover:bg-amber-700 text-white px-3.5 py-1.5 text-xs font-bold transition shadow-xs"
              >
                Duyệt nghỉ phép
              </Link>
              <Link
                href="/overtime?tab=approvals"
                className="rounded-xl bg-white border border-amber-300 text-amber-800 px-3.5 py-1.5 text-xs font-bold hover:bg-amber-50 transition"
              >
                Duyệt tăng ca
              </Link>
            </div>
          </div>
        )}

        {/* Chấm công hôm nay: status + giờ vào/ra, lấy từ /api/dashboard/summary.
            Dải 1 dòng, không phải card — navbar đã có link tới bảng chấm công. */}
        <div className="flex w-fit max-w-full flex-wrap items-center gap-x-3 gap-y-1 rounded-xl bg-white px-3.5 py-2 shadow-xs border border-slate-200/80">
          <span className="flex items-center gap-1.5">
            <span className={`h-2 w-2 rounded-full ${isDayOff ? 'bg-slate-300' : BAD_STATUS.includes(todayStatus) ? 'bg-amber-500' : 'bg-emerald-500'}`} />
            <span className={`text-xs font-bold ${isDayOff ? 'text-slate-500' : BAD_STATUS.includes(todayStatus) ? 'text-amber-600' : 'text-emerald-600'}`}>
              {statusText}
            </span>
          </span>
          {clockIn && (
            <span className="text-[11px] text-slate-500">Vào <strong className="font-mono font-bold text-slate-900">{clockIn.slice(0, 5)}</strong></span>
          )}
          {clockOut && (
            <span className="text-[11px] text-slate-500">Ra <strong className="font-mono font-bold text-slate-900">{clockOut.slice(0, 5)}</strong></span>
          )}
        </div>

        {/* Monthly KPI Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
            {/* Stat 1: Working Days */}
            <div className="rounded-3xl bg-white p-6 shadow-xs border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Công tháng này</span>
                <span className="p-2.5 rounded-xl bg-blue-50 text-blue-600"><Clock className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black text-slate-900">{workedDays}</span>
                  <span className="text-xs text-slate-400 font-medium">/ {standardDays} ngày chuẩn</span>
                </div>
                <div className="mt-2.5 w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all duration-500"
                    style={{ width: `${Math.min(100, Math.round((workedDays / (standardDays || 22)) * 100))}%` }}
                  />
                </div>
              </div>
              <p className="mt-3 text-[11px] text-slate-500">
                Tổng giờ làm việc: <strong>{summaryData?.monthSummary?.totalWorkHours ?? (workedDays * 8)}</strong> giờ
              </p>
            </div>

            {/* Stat 2: Annual Leave Balance */}
            <div className="rounded-3xl bg-white p-6 shadow-xs border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Quỹ phép năm còn lại</span>
                <span className="p-2.5 rounded-xl bg-indigo-50 text-indigo-600"><CalendarDays className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black text-indigo-600">{remainingLeaves}</span>
                  <span className="text-xs text-slate-400 font-medium">/ {currentUser?.annualLeaveDays || 12} ngày</span>
                </div>
                <div className="mt-2 text-xs text-slate-600">
                  Đã sử dụng: <strong>{currentUser?.usedLeaveDays || 0} ngày phép</strong>
                </div>
              </div>
              <Link href="/leave" className="mt-3 text-[11px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                <span>Nộp đơn xin nghỉ phép</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>

            {/* Stat 3: Overtime Hours */}
            <div className="rounded-3xl bg-white p-6 shadow-xs border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Tăng ca (OT) tháng này</span>
                <span className="p-2.5 rounded-xl bg-orange-50 text-orange-600"><Briefcase className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl font-black text-orange-600">{otHours}</span>
                  <span className="text-xs text-slate-400 font-medium">giờ tăng ca</span>
                </div>
              </div>
              <Link href="/overtime" className="mt-3 text-[11px] font-bold text-orange-600 hover:text-orange-700 flex items-center gap-1">
                <span>Xem bản ghi tăng ca</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>

            {/* Stat 4: Discipline & Late Days */}
            <div className="rounded-3xl bg-white p-6 shadow-xs border border-slate-200/80 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Kỷ luật & Đi muộn</span>
                <span className="p-2.5 rounded-xl bg-emerald-50 text-emerald-600"><TrendingUp className="h-5 w-5" /></span>
              </div>
              <div className="mt-4">
                <div className="flex items-baseline gap-2">
                  <span className={`text-3xl font-black ${lateDays > 0 ? 'text-amber-600' : 'text-emerald-600'}`}>
                    {lateDays}
                  </span>
                  <span className="text-xs text-slate-400 font-medium">buổi đi muộn / về sớm</span>
                </div>
                <p className="mt-1 text-[11px] text-slate-500">
                  {lateDays === 0 ? 'Tuyệt vời! Chấp hành xuất sắc giờ giấc công ty' : 'Cần chú ý tuân thủ thời gian ca làm việc'}
                </p>
              </div>
              <Link href="/payroll" className="mt-3 text-[11px] font-bold text-emerald-600 hover:text-emerald-700 flex items-center gap-1">
                <span>Mở bảng lương & thu nhập</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>
        </div>

        {/* Quick Module Navigation Tiles */}
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
              <div className="text-[11px] text-slate-500">Lịch sử & timesheets</div>
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
              <div className="text-[11px] text-slate-500">Đăng ký & duyệt phép</div>
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
              <div className="text-[11px] text-slate-500">Đăng ký & hệ số OT</div>
            </div>
          </Link>

          <Link
            href="/chat"
            className="flex items-center gap-3 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:border-blue-400 hover:shadow-md transition group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 group-hover:scale-105 transition">
              <Bot className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xs font-bold text-slate-900">Trợ Lý AI RAG</div>
              <div className="text-[11px] text-slate-500">Tra cứu quy chế nội bộ</div>
            </div>
          </Link>
        </div>

        {/* Việc cần bạn xử lý — lối tắt theo vai trò. Không phải menu: đây là
            những việc ĐẶC QUYỀN RIÊNG mà nhân viên thường không có.
            Số đếm chỉ có cho nghỉ phép/OT (summary endpoint đã trả sẵn);
            nghỉ việc và tính lương không có counter → để trống, không bịa. */}
        {roleTasks.length > 0 && (
          <div>
            <h2 className="mb-3 text-xs font-bold uppercase tracking-wider text-slate-400">Việc cần bạn xử lý</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
              {roleTasks.map(t => (
                <Link
                  key={t.href}
                  href={t.href}
                  className="flex items-center gap-3 p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:border-blue-300 hover:shadow-md transition group"
                >
                  <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${t.iconBg} group-hover:scale-105 transition`}>
                    <t.icon className={`h-5 w-5 ${t.iconFg}`} />
                  </div>
                  <div className="min-w-0">
                    <div className="text-xs font-bold text-slate-900">{t.name}</div>
                    <div className="text-[11px] text-slate-500 truncate">{t.desc}</div>
                  </div>
                  {t.count ? (
                    <span className="ml-auto shrink-0 rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-700">{t.count}</span>
                  ) : null}
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
